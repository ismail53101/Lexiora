/**
 * Sapiora AI Assistant gateway.
 *
 * The Flutter app talks ONLY to this Worker (SAPIORA_AI_BASE_URL points
 * here). This Worker holds the real upstream provider credentials as Worker
 * secrets and is the only thing that ever calls them — no provider key exists
 * in the app, in git, or in any client-visible place.
 *
 * Endpoint:  POST /v1/chat/completions   (OpenAI-compatible body)
 *
 * Provider selection (checked in this order — first one present wins):
 *   1. HTTP header  X-AI-Provider: forge | hcnsec | tokenrouter | openrouter | unorouter | auto
 *   2. JSON body    { "provider": "forge" | "hcnsec" | "tokenrouter" | "openrouter" | "unorouter" | "auto" }
 *   3. env.DEFAULT_PROVIDER (falls back to "hcnsec" if unset)
 *
 * "auto" (the app's default) tries every configured provider in a deterministic
 * order, starting with env.DEFAULT_PROVIDER when configured and then trying
 * the remaining configured providers if an attempt fails before any response
 * body has been sent to the client (connection error, timeout, or non-2xx).
 * Once a provider's response has started streaming
 * to the client, the response is never switched mid-stream (that's not a
 * meaningful retry point for an OpenAI-compatible proxy).
 *
 * ── Remotely-configurable, provider-agnostic model pool ("unorouter") ─────
 * Selecting the "unorouter" slot (via header, body, or DEFAULT_PROVIDER —
 * same as always) no longer means "call UnoRouter with a fixed model". It
 * means "run the generic, KV-configured pool": an ordered list of
 * {provider, model} entries, each pointing at its own OpenAI-compatible
 * provider (its own base URL + its own Worker Secret), tried in priority
 * order until one succeeds. UnoRouter and xKiro are just two entries in that
 * pool, not special cases — a future provider is added the same way they
 * were.
 *
 * Two KV values (binding: MODEL_CONFIG_KV, same namespace as before) drive
 * this:
 *   - "provider_config" — WHICH providers exist: name, base URL, and which
 *     Worker Secret holds its API key. See getProviderConfig() below.
 *   - "model_config"    — WHICH models to try, in what order, and whether
 *     each is free or paid. See getModelConfig() below.
 * A third value, "policy" ({"allow_paid": false}), gates paid models
 * globally — see getPolicy() and callDynamicPool(). Production defaults to
 * free-only.
 *
 * If KV is unbound/unreadable/empty, the Worker falls back to
 * DEFAULT_PROVIDER_CONFIG + DEFAULT_MODEL_CONFIG below — the same UnoRouter
 * + free-model setup that worked before this change — so the Assistant
 * keeps working either way. The legacy "model_pool" KV key (UnoRouter-only
 * model list) is still read as a secondary fallback if "model_config" isn't
 * set yet, so nothing already written to KV is lost.
 *
 * See getProviderConfig()/getModelConfig()/getPolicy()/callDynamicPool()
 * below and README.md for the exact KV formats, examples, and deploy steps.
 *
 * ── Adding a future OpenAI-compatible provider (no code, no Flutter, no APK) ─
 * Write updated "provider_config" and "model_config" JSON to KV (Cloudflare
 * dashboard or `wrangler kv key put`) and set its Worker Secret. That's it —
 * see README.md.
 *
 * ── Adding a provider that ISN'T fully OpenAI-compatible ──────────────────
 * Add one small entry to PROVIDER_ADAPTERS below (how to build the outgoing
 * request for that wire format), reference it as "adapter" in that
 * provider's KV entry, and set its secret. Still no Flutter change, and the
 * routing/fallback loop above doesn't change either.
 *
 * ── Adding a legacy header-selectable provider (forge/hcnsec/openrouter-style) ─
 * These are unrelated to the KV pool above — they're chosen explicitly via
 * `X-AI-Provider: <name>` and read one fixed model from env/secrets. To add
 * one: add its base URL + secret name to PROVIDERS below, then
 * `wrangler secret put <NAME>_API_KEY`. Nothing else changes.
 */

/** @type {Record<string, { baseUrlEnv: string, apiKeyEnv: string, defaultBaseUrl?: string, modelEnv?: string, defaultModel?: string }>} */
const PROVIDERS = {
  forge: { baseUrlEnv: "FORGE_BASE_URL", apiKeyEnv: "FORGE_API_KEY" },
  hcnsec: {
    baseUrlEnv: "HCNSEC_BASE_URL",
    apiKeyEnv: "HCNSEC_API_KEY",
    defaultBaseUrl: "https://api.hcnsec.cn",
  },
  tokenrouter: {
    baseUrlEnv: "TOKENROUTER_BASE_URL",
    apiKeyEnv: "TOKENROUTER_API_KEY",
    defaultBaseUrl: "https://api.tokenrouter.com",
    // The app sends a generic "auto"/"model" value it doesn't control the
    // meaning of — TokenRouter needs its own real model id, so it's
    // substituted in whenever this provider is used (see providerModel()).
    modelEnv: "TOKENROUTER_MODEL",
    defaultModel: "moonshotai/kimi-k3-free",
  },
  openrouter: {
    baseUrlEnv: "OPENROUTER_BASE_URL",
    apiKeyEnv: "OPENROUTER_API_KEY",
    defaultBaseUrl: "https://openrouter.ai/api/v1",
    modelEnv: "OPENROUTER_MODEL",
    defaultModel: "stealth/ox-alpha",
  },
  // No modelEnv/defaultModel here on purpose — unlike the providers above,
  // "unorouter" doesn't send one fixed model. Its model comes from the
  // remotely-configurable pool in KV; see callUnorouterPool() below.
  unorouter: {
    baseUrlEnv: "UNOROUTER_BASE_URL",
    apiKeyEnv: "UNOROUTER_API_KEY",
    defaultBaseUrl: "https://api.unorouter.com",
  },
};

const CHAT_COMPLETIONS_PATH = "/v1/chat/completions";

function chatCompletionsUrl(baseUrl) {
  const normalized = baseUrl.replace(/\/+$/, "");
  if (normalized.endsWith(CHAT_COMPLETIONS_PATH)) return normalized;
  if (normalized.endsWith("/v1")) return `${normalized}/chat/completions`;
  return `${normalized}${CHAT_COMPLETIONS_PATH}`;
}

// ── Generic, remotely-configurable provider/model pool (KV) ────────────────
// All three live in the same MODEL_CONFIG_KV namespace as before.
const PROVIDER_CONFIG_KV_KEY = "provider_config"; // which providers exist
const MODEL_CONFIG_KV_KEY = "model_config";        // which models, in what order
const POLICY_KV_KEY = "policy";                    // { "allow_paid": false }

// Legacy key from the UnoRouter-only model pool this replaces. Still read as
// a fallback if "model_config" hasn't been written yet, so an
// already-deployed KV value keeps working unchanged.
const LEGACY_MODEL_POOL_KV_KEY = "model_pool";

// Used only if MODEL_CONFIG_KV is unbound, unreadable, or empty/invalid for
// BOTH "provider_config"/"model_config" and the legacy "model_pool" key —
// keeps the AI Assistant working even if the remote config can't be read.
// This is intentionally identical to the UnoRouter setup that worked before
// this pool became provider-agnostic. Not a permanent list: change it any
// time via KV, never by editing this file (see README.md).
const DEFAULT_MODEL_POOL = [
  "deepseek-v4.1-flash:free",
  "qwen3.5-122b-a10b:free",
  "agnes-2.0-flash:free",
  "glm-4.7-flash:free",
];

const DEFAULT_PROVIDER_CONFIG = [
  {
    name: "unorouter",
    baseUrl: "https://api.unorouter.com",
    secretName: "UNOROUTER_API_KEY",
    enabled: true,
    adapter: "openai",
  },
];

const DEFAULT_MODEL_CONFIG = DEFAULT_MODEL_POOL.map((model, index) => ({
  provider: "unorouter",
  model,
  enabled: true,
  priority: index + 1,
  tier: "free",
}));

// Production default: never call a model marked "paid" unless KV's "policy"
// value explicitly sets allow_paid: true.
const DEFAULT_POLICY = { allow_paid: false };

/**
 * How to build the outgoing request for a given provider's wire format. The
 * generic pool below (callDynamicPool) looks up a provider's "adapter" field
 * (defaulting to "openai") in this map — that's the ONLY place a
 * not-fully-OpenAI-compatible provider needs code. Everything else (KV
 * schema, routing, fallback, Flutter) is unaffected by adding one.
 */
const PROVIDER_ADAPTERS = {
  openai: {
    buildRequest(target, apiKey, bodyText, model) {
      return {
        url: target,
        init: {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
            "User-Agent": "Sapiora-AI-Gateway/1.0 (+Cloudflare-Worker)",
            Authorization: `Bearer ${apiKey}`,
          },
          body: rewriteModel(bodyText, model),
        },
      };
    },
  },
};

// Hard ceiling on how many {provider, model} attempts callDynamicPool() will
// make per request, regardless of how many entries KV contains — keeps
// fallback bounded even if someone pastes in a huge model_config.
const MAX_POOL_ATTEMPTS = 20;

// Bounded per-model timeout so one unresponsive free model can't stall the
// whole request — it's abandoned and the next model in the pool is tried.
const MODEL_ATTEMPT_TIMEOUT_MS = 15000;

// Whole-request budget for provider attempts. The app waits at most 60s for
// response headers, so the Worker must answer (success OR a clean error)
// well inside that. Without this, 4 slow free models x 25s + fallbacks ran
// past every timeout and the user saw Cloudflare's raw "error 522".
const TOTAL_AI_BUDGET_MS = 42000;
const LEGACY_PROVIDER_TIMEOUT_MS = 20000;
const MIN_ATTEMPT_MS = 2500;

// Upstream statuses that mean "that host is down/unreachable", so its other
// models would fail the same way (502/503/504 and Cloudflare 520-524).
function isHostDownStatus(status) {
  return status === 502 || status === 503 || status === 504 ||
    (status >= 520 && status <= 527);
}
const NEWS_CACHE_KEY = "https://sapiora.internal/cache/current-affairs/latest-v1";
const STANDS4_CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const STANDS4_CACHE_PREFIX = "https://sapiora.internal/cache/stands4/";
const NEWS_CACHE_TTL_MS = 15 * 60 * 1000;
const NEWS_FRESHNESS_WINDOW_MS = 48 * 60 * 60 * 1000;
const MAX_LATEST_STORIES_PER_CATEGORY = 40;
const MAX_OPINION_STORIES_PER_CATEGORY = 20;
const MAX_GNEWS_STORIES_PER_CATEGORY = 20;
// GNews free plan: 100 requests/day, 10 articles/request, 1 request/second.
// The cron runs every 15 min, so GNews results are cached (KV, global) and the
// API is only called when the cache is older than GNEWS_CACHE_MINUTES. If the
// API fails (quota, 429, network) the last good result is reused for up to 24h.
// Optional Worker vars: GNEWS_MAX (articles per request, default 10; raise it
// on a paid plan) and GNEWS_CACHE_MINUTES (default 60).
const GNEWS_DEFAULT_MAX = 10;
const GNEWS_DEFAULT_CACHE_MINUTES = 60;
const GNEWS_STALE_MAX_MS = 24 * 60 * 60 * 1000;

const INTERNATIONAL_NEWS_MARKERS = [
  'united states', 'u.s.', 'usa', 'united kingdom', 'european union',
  'europe', 'russia', 'ukraine', 'china', 'taiwan', 'israel', 'gaza',
  'palestine', 'iran', 'iraq', 'afghanistan', 'india', 'bangladesh',
  'sri lanka', 'nepal', 'united nations', 'nato', 'donald trump',
  'white house', 'european parliament',
];
const PAKISTAN_NEWS_MARKERS = [
  'pakistan', 'pakistani', 'islamabad', 'rawalpindi', 'lahore', 'karachi',
  'peshawar', 'quetta', 'balochistan', 'sindh', 'punjab', 'khyber',
  'gilgit', 'azad kashmir', 'prime minister', 'national assembly',
  'senate of pakistan', 'state bank of pakistan',
];

const RELEVANCE_BOOSTS = [
  ['politic', 8],
  ['government', 8],
  ['minister', 6],
  ['parliament', 6],
  ['election', 7],
  ['diplom', 7],
  ['foreign affair', 8],
  ['geopolit', 8],
  ['econom', 7],
  ['inflation', 6],
  ['trade', 5],
  ['security', 7],
  ['defen', 6],
  ['terror', 7],
  ['conflict', 6],
  ['war', 5],
  ['climate', 7],
  ['environment', 5],
  ['science', 6],
  ['research', 4],
  ['united nations', 7],
  ['nato', 6],
  ['g20', 6],
  ['summit', 5],
  ['sanction', 5],
  ['earthquake', 5],
  ['disaster', 5],
  ['pandemic', 6],
  ['court', 4],
  ['supreme', 5],
];
const RELEVANCE_PENALTIES = [
  ['entertainment', 10],
  ['celebrity', 10],
  ['hollywood', 8],
  ['bollywood', 8],
  ['film', 7],
  ['movie', 7],
  ['music', 6],
  ['cricket', 5],
  ['football', 5],
  ['sports', 5],
];
const NEWS_SOURCES = [
  // Pakistan — official latest-news and opinion feeds.
  { id: "dawn-latest-news", name: "Dawn", category: "National", feedType: "Latest News", url: "https://www.dawn.com/feeds/latest-news" },
  { id: "dawn-opinion", name: "Dawn", category: "National", feedType: "Opinions", url: "https://www.dawn.com/feeds/opinion" },
  { id: "express-tribune-pakistan", name: "Express Tribune", category: "National", feedType: "Latest News", url: "https://tribune.com.pk/feed/pakistan" },
  { id: "the-news-pakistan", name: "The News", category: "National", feedType: "Latest News", url: "https://www.thenews.com.pk/rss/1/0" },
  // World — sources intended to remain accessible for Pakistan users.
  { id: "bbc-world", name: "BBC World", category: "International", feedType: "Latest News", url: "https://feeds.bbci.co.uk/news/world/rss.xml" },
  // Reuters no longer exposes a dependable public world RSS endpoint. This
  // Google News RSS query is restricted to Reuters world articles and keeps
  // the original Reuters links in each parsed story.
  { id: "reuters-world", name: "Reuters", category: "International", feedType: "Latest News", url: "https://news.google.com/rss/search?q=site%3Areuters.com%2Fworld&hl=en-US&gl=US&ceid=US:en" },
  { id: "express-tribune-world", name: "Express Tribune", category: "International", feedType: "Latest News", url: "https://tribune.com.pk/feed/world" },
  { id: "the-news-world", name: "The News", category: "International", feedType: "Latest News", url: "https://www.thenews.com.pk/rss/1/2" },
  // GNews articles are merged with RSS articles. Set the Worker secret
  // GNEWS_API_KEY to enable these sources; RSS remains the fallback.
  { id: "gnews-pakistan", name: "GNews", category: "National", feedType: "gnews", kind: "gnews", categoryParam: "nation", country: "pk" },
  { id: "gnews-world", name: "GNews", category: "International", feedType: "gnews", kind: "gnews", categoryParam: "world", staggerMs: 1200 },
];
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",

  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-AI-Provider",
  "Access-Control-Expose-Headers": "X-AI-Provider-Used, X-Sapiora-Web, X-Sapiora-Sources",
};

export default {
  /**
   * @param {Request} request
   * @param {Record<string, string>} env
   */
    async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }
    const url = new URL(request.url);
    if (url.pathname === "/api/dictionary/lookup") {
      if (request.method !== "GET") {
        return jsonError(405, "method_not_allowed", "Use GET.");
      }
      if (!isWorkerAuthorized(request, env)) {
        return jsonError(401, "unauthorized", "Invalid or missing API key.");
      }
      return stands4DictionaryResponse(url, env);
    }
    if (url.pathname === "/api/current-affairs/latest") {
      if (request.method !== "GET") {
        return jsonError(405, "method_not_allowed", "Use GET.");
      }
      return currentAffairsResponse(ctx, env);
    }

    if (url.pathname !== CHAT_COMPLETIONS_PATH) {
      return jsonError(404, "not_found", `Unknown path: ${url.pathname}`);
    }
    if (request.method !== "POST") {
      return jsonError(405, "method_not_allowed", "Use POST.");
    }

    // ── Gate access with the Worker's own shared key ────────────────────────
    // This is the "SAPIORA_AI_API_KEY" the Flutter app sends — a token this
    // Worker itself defines, completely separate from the real Forge/HCNSEC
    // keys. Without it, anyone who finds the Worker's URL could rack up
    // usage on your real provider accounts.
    if (env.WORKER_SHARED_KEY) {
      const auth = request.headers.get("Authorization") || "";
      const token = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
      if (token !== env.WORKER_SHARED_KEY) {
        return jsonError(401, "unauthorized", "Invalid or missing API key.");
      }
    }

    let bodyText;
    try {
      bodyText = await request.text();
    } catch {
      return jsonError(400, "bad_request", "Could not read request body.");
    }

    /** @type {any} */
    let body;
    try {
      body = JSON.parse(bodyText);
    } catch {
      return jsonError(400, "bad_request", "Request body is not valid JSON.");
    }

    // ── Web search (Firecrawl) ──────────────────────────────────────────────
    // If the message needs current info (or contains a URL), fetch pages via
    // Firecrawl and add them to the prompt. Never throws: on any failure the
    // request continues normally without web context.
    const web = await addWebContext(body, env);
    body = web.body;
    bodyText = JSON.stringify(body);
    const webSources = web.sources;

    const requested = pickRequestedProvider(request, body, env);
    const order = resolveProviderOrder(requested, env);
    if (order.length === 0) {
      return jsonError(
        503,
        "no_provider_configured",
        "No AI provider is configured on the Worker.",
      );
    }

    let lastFailure = null;
    const deadline = Date.now() + TOTAL_AI_BUDGET_MS;

    for (let i = 0; i < order.length; i++) {
      const providerId = order[i];
      const isLastAttempt = i === order.length - 1;

      if (i > 0 && deadline - Date.now() < MIN_ATTEMPT_MS) {
        break; // out of time budget: answer with a clean error below
      }

      let upstream;
      try {
        upstream = await callProvider(providerId, bodyText, env, deadline);
      } catch (err) {
        // Network-level failure (DNS, TLS, timeout, ...) — try the next
        // provider if there is one.
        lastFailure = { status: 502, message: `${providerId}: ${err.message || "network error"}` };
        if (!isLastAttempt) continue;
        return jsonError(503, "provider_unreachable", lastFailure.message);
      }

      if (upstream.ok) {
        // Success — stream this response straight through to the client.
        // Streaming (SSE) bodies pass through untouched; Cloudflare Workers
        // proxy the ReadableStream natively, so no buffering happens here.
        const headers = new Headers(CORS_HEADERS);
        const contentType = upstream.headers.get("content-type");
        if (contentType) headers.set("Content-Type", contentType);
        headers.set("X-AI-Provider-Used", providerId);
        if (webSources.length > 0) {
          headers.set("X-Sapiora-Web", "1");
          headers.set("X-Sapiora-Sources", encodeSourcesHeader(webSources));
        }
        return new Response(upstream.body, { status: 200, headers });
      }

      // Non-2xx from this provider (bad key, rate limited, provider down, a
      // model name it doesn't recognise, ...) — capture it and, if another
      // provider is available, fall back to it instead of failing the
      // request outright.
      const text = await upstream.text().catch(() => "");
      lastFailure = { status: upstream.status, message: text || upstream.statusText };
      if (!isLastAttempt) continue;

      return aiUnavailable(lastFailure, providerId);
    }

    // Every provider failed or the time budget ran out.
    return aiUnavailable(lastFailure, null);
  },
  async scheduled(controller, env, ctx) {
    ctx.waitUntil(refreshCurrentAffairs(env));
  },
};
function isWorkerAuthorized(request, env) {
  if (!env.WORKER_SHARED_KEY) return true;
  const auth = request.headers.get("Authorization") || "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
  return token === env.WORKER_SHARED_KEY;
}

async function stands4DictionaryResponse(url, env) {
  const word = (url.searchParams.get("word") || "").trim().toLowerCase();
  if (!word || word.length > 80) {
    return jsonError(400, "invalid_word", "Provide one dictionary word.");
  }
  if (!env.STANDS4_UID || !env.STANDS4_TOKEN) {
    return jsonError(503, "stands4_not_configured", "STANDS4 is not configured.");
  }

  const cacheKey = new Request(`${STANDS4_CACHE_PREFIX}${encodeURIComponent(word)}`);
  const cached = await caches.default.match(cacheKey);
  if (cached) {
    const cachedPayload = await cached.clone().json().catch(() => null);
    if (cachedPayload && Date.now() - cachedPayload.fetchedAt < STANDS4_CACHE_TTL_MS) {
      return withCors(cached);
    }
  }

  const params = new URLSearchParams({
    uid: env.STANDS4_UID,
    tokenid: env.STANDS4_TOKEN,
    word,
    format: "json",
  });
  const headers = { "User-Agent": "Lexiora-Dictionary/1.0" };
  const [definitionsResponse, synonymsResponse] = await Promise.all([
    fetch(`https://www.stands4.com/services/v2/defs.php?${params}`, { headers }),
    fetch(`https://www.stands4.com/services/v2/syno.php?${params}`, { headers }),
  ]);
  if (!definitionsResponse.ok && !synonymsResponse.ok) {
    return jsonError(502, "stands4_unavailable", "STANDS4 lookup failed.");
  }

  const definitions = await definitionsResponse.json().catch(() => null);
  const synonyms = await synonymsResponse.json().catch(() => null);
  const definition = firstStands4Result(definitions);
  const thesaurus = firstStands4Result(synonyms);
  const payload = {
    fetchedAt: Date.now(),
    word,
    englishDefinition: cleanText(definition?.definition || thesaurus?.definition || ""),
    partOfSpeech: cleanText(definition?.partofspeech || thesaurus?.partofspeech || ""),
    exampleSentence: cleanText(definition?.example || ""),
    synonyms: splitStands4List(thesaurus?.synonyms),
    antonyms: splitStands4List(thesaurus?.antonyms),
    source: "stands4",
  };
  const response = jsonResponse(payload);
  await caches.default.put(cacheKey, response.clone());
  return response;
}

function firstStands4Result(payload) {
  const result = payload?.results?.result;
  if (Array.isArray(result)) return result[0] || null;
  return result && typeof result === "object" ? result : null;
}

function splitStands4List(value) {
  if (typeof value !== "string") return [];
  return value.split(",").map((item) => cleanText(item)).filter(Boolean).slice(0, 12);
}

async function currentAffairsResponse(ctx, env) {
  const cache = caches.default;
  const cached = await cache.match(NEWS_CACHE_KEY);
  if (cached) {
    const payload = await cached.clone().json().catch(() => null);
    if (payload && Date.now() - payload.fetchedAt < NEWS_CACHE_TTL_MS) {
      return withCors(cached);
    }
  }

  const payload = await refreshCurrentAffairs(env);
  const response = jsonResponse(payload);
  ctx.waitUntil(cache.put(new Request(NEWS_CACHE_KEY), response.clone()));
  return response;
}

async function refreshCurrentAffairs(env) {
  const settled = await Promise.allSettled(
    NEWS_SOURCES.map((source) => fetchNewsSource(source, env)),
  );
  const stories = settled.flatMap((result) =>
    result.status === "fulfilled" ? result.value : []
  );
  const freshStories = reclassifyNewsStories(
    filterFreshStories(deduplicateStories(stories)),
  );
  const payload = {
    fetchedAt: Date.now(),
    // Diagnostics only (the app ignores unknown fields): how many stories each
    // transport delivered before selection.
    counts: {
      gnews: freshStories.filter((story) => story.feedType.toLowerCase() === "gnews").length,
      rss: freshStories.filter((story) => story.feedType.toLowerCase() !== "gnews").length,
    },
    national: selectLatestStories(
      freshStories.filter((story) => story.category === "National"),
    ),
    international: selectLatestStories(
      freshStories.filter((story) => story.category === "International"),
    ),
    sources: NEWS_SOURCES.map(({ id, name, category, feedType }) => ({
      id,
      name,
      category,
      feedType,
    })),
  };
  await caches.default.put(
    new Request(NEWS_CACHE_KEY),
    jsonResponse(payload),
  );
  return payload;
}

async function fetchNewsSource(source, env) {
  if (source.kind === "gnews") return fetchGNewsSource(source, env);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10000);
  try {
    const response = await fetch(source.url, {
      headers: {
        Accept: "application/rss+xml, application/atom+xml, application/xml, text/xml",
        "User-Agent": "Sapiora-Current-Affairs/1.0 (+RSS reader)",
      },
      signal: controller.signal,
    });
    if (!response.ok) return [];
    return parseFeed(await response.text(), source);
  } finally {
    clearTimeout(timeout);
  }
}

async function fetchGNewsSource(source, env) {
  const apiKey = env.GNEWS_API_KEY;
  if (!apiKey) {
    console.log(`[gnews] ${source.id}: GNEWS_API_KEY not set`);
    return [];
  }

  const ttlMs = (Number(env.GNEWS_CACHE_MINUTES) || GNEWS_DEFAULT_CACHE_MINUTES) * 60 * 1000;
  const cached = await readGNewsCache(source, env);
  if (cached && Date.now() - cached.savedAt < ttlMs) {
    return cached.stories;
  }

  let stories = [];
  try {
    if (source.staggerMs) await sleep(source.staggerMs); // free plan: 1 request/second
    stories = await fetchGNewsFromApi(source, apiKey, env);
  } catch (err) {
    console.log(`[gnews] ${source.id}: request failed: ${err.message || err}`);
  }

  if (stories.length > 0) {
    await writeGNewsCache(source, stories, env);
    return stories;
  }

  // API returned nothing (quota used up, rate limited, outage): keep showing
  // the last good GNews stories instead of dropping to RSS only.
  if (cached && Date.now() - cached.savedAt < GNEWS_STALE_MAX_MS) {
    console.log(`[gnews] ${source.id}: using cached stories`);
    return cached.stories;
  }
  return [];
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function gnewsCacheKey(source) {
  return `gnews_cache:${source.id}`;
}

async function readGNewsCache(source, env) {
  try {
    if (env.MODEL_CONFIG_KV) {
      return await env.MODEL_CONFIG_KV.get(gnewsCacheKey(source), "json");
    }
    const hit = await caches.default.match(new Request(`https://sapiora.internal/cache/${gnewsCacheKey(source)}`));
    return hit ? await hit.json() : null;
  } catch {
    return null;
  }
}

async function writeGNewsCache(source, stories, env) {
  const value = JSON.stringify({ savedAt: Date.now(), stories });
  try {
    if (env.MODEL_CONFIG_KV) {
      await env.MODEL_CONFIG_KV.put(gnewsCacheKey(source), value, { expirationTtl: 86400 });
      return;
    }
    await caches.default.put(
      new Request(`https://sapiora.internal/cache/${gnewsCacheKey(source)}`),
      new Response(value, { headers: { "Cache-Control": "max-age=86400" } }),
    );
  } catch (err) {
    console.log(`[gnews] ${source.id}: cache write failed: ${err.message || err}`);
  }
}

async function fetchGNewsFromApi(source, apiKey, env) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10000);
  const max = String(Number(env.GNEWS_MAX) || GNEWS_DEFAULT_MAX);
  try {
    const endpoint = new URL("https://gnews.io/api/v4/top-headlines");
    endpoint.searchParams.set("lang", "en");
    endpoint.searchParams.set("max", max);
    endpoint.searchParams.set("apikey", apiKey);
    if (source.country) endpoint.searchParams.set("country", source.country);
    if (source.categoryParam) endpoint.searchParams.set("category", source.categoryParam);

    const response = await fetch(endpoint, {
      headers: { "User-Agent": "Sapiora-Current-Affairs/1.0 (+GNews reader)" },
      signal: controller.signal,
    });
    if (!response.ok) console.log(`[gnews] ${source.id}: HTTP ${response.status}`);
    let payload = response.ok ? await response.json() : null;
    if ((!payload || !Array.isArray(payload.articles) || payload.articles.length === 0) &&
        source.category === "International") {
      await sleep(1100); // free plan: 1 request/second
      const fallback = new URL("https://gnews.io/api/v4/search");
      fallback.searchParams.set("q", "international OR world");
      fallback.searchParams.set("lang", "en");
      fallback.searchParams.set("max", max);
      fallback.searchParams.set("sortby", "publishedAt");
      fallback.searchParams.set("apikey", apiKey);
      const fallbackResponse = await fetch(fallback, {
        headers: { "User-Agent": "Sapiora-Current-Affairs/1.0 (+GNews reader)" },
        signal: controller.signal,
      });
      if (!fallbackResponse.ok) console.log(`[gnews] ${source.id}: fallback HTTP ${fallbackResponse.status}`);
      if (fallbackResponse.ok) payload = await fallbackResponse.json();
    }
    if (!payload || !Array.isArray(payload.articles)) return [];
    return payload.articles.map((article) => {
      const title = cleanText(article.title || "");
      const url = typeof article.url === "string" ? article.url : "";
      if (!title || !url) return null;
      return {
        id: stableStoryId(url, title),
        title,
        source: cleanText(article.source?.name || "GNews"),
        category: source.category,
        feedType: classifyFeedType(source, url, title),
        publishedAt: validDate(article.publishedAt),
        excerpt: cleanText(article.description || article.content || "").slice(0, 500),
        imageUrl: typeof article.image === "string" ? article.image : null,
        articleUrl: url,
      };
    }).filter(Boolean);
  } finally {
    clearTimeout(timeout);
  }
}

function parseFeed(xml, source) {
  const blocks = [...xml.matchAll(/<(item|entry)\b[^>]*>([\s\S]*?)<\/\1>/gi)];
  return blocks.map((match) => {
    const block = match[2];
    const title = cleanText(readTag(block, "title"));
    const url = readLink(block);
    const description = cleanText(
      readTag(block, "description") || readTag(block, "summary") || readTag(block, "content:encoded")
    ).slice(0, 500);
    const publishedAt = readTag(block, "pubDate") || readTag(block, "dc:date") ||
      readTag(block, "published") || readTag(block, "updated");
    if (!title || !url) return null;
    return {
      id: stableStoryId(url, title),
      title,
      source: source.name,
      category: source.category,
      feedType: classifyFeedType(source, url, title),
      publishedAt: validDate(publishedAt),
      excerpt: description,
      imageUrl: readImage(block),
      articleUrl: url,
    };
  }).filter(Boolean);
}

function classifyFeedType(source, articleUrl, title) {
  if (source.feedType.toLowerCase() === "opinions") return "Opinions";
  const text = `${articleUrl} ${title}`.toLowerCase();
  return /(?:\/|\b)(?:opinion|opinions|editorial|analysis|op-ed)(?:\/|\b)/i.test(text)
    ? "Opinions"
    : source.feedType;
}
function reclassifyNewsStories(stories) {
  return stories.map((story) => {
    if (story.category !== "National") return story;
    const text = `${story.title} ${story.excerpt}`.toLowerCase();
    const mentionsPakistan = PAKISTAN_NEWS_MARKERS.some((marker) => text.includes(marker));
    const mentionsInternational = INTERNATIONAL_NEWS_MARKERS.some((marker) => text.includes(marker));
    // Pakistan feeds often carry world headlines. Move only strongly marked
    // foreign stories; Pakistan-specific stories always remain National.
    if (!mentionsPakistan && mentionsInternational) {
      return { ...story, category: "International" };
    }
    return story;
  });
}
function readTag(block, tag) {
  const match = block.match(new RegExp(`<${tag}\\b[^>]*>([\\s\\S]*?)</${tag}>`, "i"));
  return match ? match[1].trim() : "";
}

function readLink(block) {
  const atom = block.match(/<link\b[^>]*href=["']([^"']+)["'][^>]*\/?/i);
  return atom ? decodeXml(atom[1]) : decodeXml(readTag(block, "link"));
}

function readImage(block) {
  const media = block.match(/<(?:media:content|media:thumbnail|enclosure)\b[^>]*url=["']([^"']+)["']/i);
  if (media) return decodeXml(media[1]);
  const image = block.match(/<img\b[^>]*src=["']([^"']+)["']/i);
  return image ? decodeXml(image[1]) : null;
}

function cleanText(value) {
  return decodeXml(value)
    .replace(/<!\[CDATA\[|\]\]>/g, "")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function decodeXml(value) {
  return value
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'");
}

function filterFreshStories(stories, now = Date.now()) {
  return stories.filter((story) => {
    const published = dateValue(story.publishedAt);
    return published > 0 && now - published >= 0 &&
      now - published <= NEWS_FRESHNESS_WINDOW_MS;
  });
}

function selectLatestStories(stories) {
  if (stories.length === 0) return [];

  const opinions = stories.filter((story) => story.feedType.toLowerCase() === "opinions");
  const latest = stories.filter((story) => story.feedType.toLowerCase() !== "opinions");
  const gnews = latest.filter((story) => story.feedType.toLowerCase() === "gnews");
  const rss = latest.filter((story) => story.feedType.toLowerCase() !== "gnews");

  // Rank each transport independently so a large RSS batch cannot crowd every
  // GNews article out of the response. Up to 20 GNews and 20 RSS stories are
  // retained per category, with either side filling unused slots.
  const selectedLatest = interleaveTransports(
    rankedStories(gnews).slice(0, MAX_GNEWS_STORIES_PER_CATEGORY),
    rankedStories(rss),
    MAX_LATEST_STORIES_PER_CATEGORY,
  );
  const selectedOpinions = rankedStories(opinions)
    .slice(0, MAX_OPINION_STORIES_PER_CATEGORY)
    .sort((a, b) => dateValue(b.publishedAt) - dateValue(a.publishedAt));

  // Latest stories alternate GNews / RSS (each side newest-first) so GNews is
  // not pushed down the list by the many RSS feeds; opinions follow.
  return [...selectedLatest, ...selectedOpinions];
}

function rankedStories(stories) {
  const scored = stories.map((story) => ({ story, score: relevanceScore(story) }));
  const relevant = scored.filter((entry) => entry.score > 0);
  const candidates = relevant.length > 0 ? relevant : scored;
  return candidates
    .sort((a, b) => dateValue(b.story.publishedAt) - dateValue(a.story.publishedAt))
    .map((entry) => entry.story);
}

function interleaveTransports(gnews, rss, limit) {
  const out = [];
  let g = 0;
  let r = 0;
  // Start with whichever side has the newest story, then alternate.
  let takeGnews = dateValue(gnews[0]?.publishedAt) > dateValue(rss[0]?.publishedAt);
  while (out.length < limit && (g < gnews.length || r < rss.length)) {
    if (takeGnews && g < gnews.length) out.push(gnews[g++]);
    else if (!takeGnews && r < rss.length) out.push(rss[r++]);
    else if (g < gnews.length) out.push(gnews[g++]);
    else out.push(rss[r++]);
    takeGnews = !takeGnews;
  }
  return out;
}

function relevanceScore(story) {
  const text = `${story.title} ${story.excerpt}`.toLowerCase();
  let score = 0;
  for (const [keyword, weight] of RELEVANCE_BOOSTS) {
    if (text.includes(keyword)) score += weight;
  }
  for (const [keyword, weight] of RELEVANCE_PENALTIES) {
    if (text.includes(keyword)) score -= weight;
  }
  return score;
}

function dateValue(value) {
  const time = Date.parse(value || '');
  return Number.isNaN(time) ? 0 : time;
}

function validDate(value) {
  const time = Date.parse(value || "");
  return Number.isNaN(time) ? null : new Date(time).toISOString();
}

function stableStoryId(url, title) {
  return (url || title).toLowerCase().replace(/[^a-z0-9]+/g, "-").slice(0, 180);
}

function deduplicateStories(stories) {
  const seen = new Set();
  return stories.filter((story) => {
    const key = stableStoryId(story.articleUrl, story.title);
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json; charset=utf-8" },
  });
}

function withCors(response) {
  const headers = new Headers(response.headers);
  Object.entries(CORS_HEADERS).forEach(([key, value]) => headers.set(key, value));
  return new Response(response.body, { status: response.status, headers });
}

/**
 * Header takes precedence over the body field, since it doesn't require
 * parsing/trusting the JSON payload's shape.
 */
function pickRequestedProvider(request, body, env) {
  const header = request.headers.get("X-AI-Provider");
  if (header && isKnownOrAuto(header)) return header.toLowerCase();

  const fromBody = typeof body?.provider === "string" ? body.provider : null;
  if (fromBody && isKnownOrAuto(fromBody)) return fromBody.toLowerCase();

  return (env.DEFAULT_PROVIDER || "auto").toLowerCase();
}

function isKnownOrAuto(value) {
  const v = value.toLowerCase();
  return v === "auto" || Object.prototype.hasOwnProperty.call(PROVIDERS, v);
}

/**
 * Builds the ordered list of providers to try. "auto" tries the configured
 * default first, then every other configured provider as fallback. An
 * explicit provider name is tried alone — no silent fallback to a provider
 * the caller didn't ask for.
 */
function resolveProviderOrder(requested, env) {
  const configured = Object.keys(PROVIDERS).filter((id) => providerApiKey(id, env));

  if (requested !== "auto") {
    return configured.includes(requested) ? [requested] : [];
  }
  const preferredDefault = (env.DEFAULT_PROVIDER || "unorouter").toLowerCase();
  const rest = configured.filter((id) => id !== preferredDefault);
  return configured.includes(preferredDefault)
    ? [preferredDefault, ...rest]
    : configured; // configured default provider has no key set — just try what's available
}

function providerApiKey(id, env) {
  if (id === "unorouter") {
    // The generic pool may be backed entirely by xKiro or another provider in
    // MODEL_CONFIG_KV, so it must not depend on a legacy UnoRouter key.
    return env.MODEL_CONFIG_KV || env.UNOROUTER_API_KEY;
  }
  return env[PROVIDERS[id].apiKeyEnv];
}

function providerBaseUrl(id, env) {
  const cfg = PROVIDERS[id];
  return env[cfg.baseUrlEnv] || cfg.defaultBaseUrl;
}

/** The real model id to send this provider, if it needs a specific one
 * rather than whatever generic value the app sent (e.g. "auto"). */
function providerModel(id, env) {
  const cfg = PROVIDERS[id];
  if (!cfg.modelEnv && !cfg.defaultModel) return null;
  return (cfg.modelEnv && env[cfg.modelEnv]) || cfg.defaultModel || null;
}

/** Never leak an upstream's raw status (e.g. Cloudflare 522) to the app: a
 * dead upstream is reported as a clean 503 the app knows how to retry;
 * only a real 429 is passed through. */
function aiUnavailable(failure, providerId) {
  const upstreamStatus = failure?.status ?? 0;
  const status = upstreamStatus === 429 ? 429 : 503;
  const message = String(failure?.message || "All AI providers are unavailable.")
    .replace(/\s+/g, " ")
    .slice(0, 300);
  return jsonError(
    status,
    status === 429 ? "rate_limited" : "ai_unavailable",
    message,
    { upstreamStatus, ...(providerId ? { provider: providerId } : {}) },
  );
}

async function callProvider(id, bodyText, env, deadline) {
  if (id === "unorouter") {
    // "unorouter" is the trigger for the generic, KV-configured pool — it
    // may call UnoRouter, xKiro, or any other configured provider depending
    // on provider_config/model_config. See callDynamicPool() below.
    return callDynamicPool(bodyText, env, deadline);
  }
  const baseUrl = providerBaseUrl(id, env);
  if (!baseUrl) {
    throw new Error(`${id}: no base URL configured (set ${PROVIDERS[id].baseUrlEnv})`);
  }
  const apiKey = providerApiKey(id, env);
  const target = chatCompletionsUrl(baseUrl);
  const outgoingBody = rewriteModel(bodyText, providerModel(id, env));

  const legacyTimeout = Math.max(
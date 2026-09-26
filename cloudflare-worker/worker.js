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
const MODEL_ATTEMPT_TIMEOUT_MS = 25000;
const NEWS_CACHE_KEY = "https://sapiora.internal/cache/current-affairs/latest-v1";
const NEWS_CACHE_TTL_MS = 15 * 60 * 1000;
const NEWS_FRESHNESS_WINDOW_MS = 48 * 60 * 60 * 1000;

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
  // World — official world/latest feeds. No unsupported category feed is guessed.
  { id: "bbc-world", name: "BBC World", category: "International", feedType: "Latest News", url: "https://feeds.bbci.co.uk/news/world/rss.xml" },
  { id: "al-jazeera-world", name: "Al Jazeera", category: "International", feedType: "Latest News", url: "https://www.aljazeera.com/xml/rss/all.xml" },
  { id: "express-tribune-world", name: "Express Tribune", category: "International", feedType: "Latest News", url: "https://tribune.com.pk/feed/world" },
  { id: "the-news-world", name: "The News", category: "International", feedType: "Latest News", url: "https://www.thenews.com.pk/rss/1/2" },
];
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",

  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-AI-Provider",
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
    if (url.pathname === "/api/current-affairs/latest") {
      if (request.method !== "GET") {
        return jsonError(405, "method_not_allowed", "Use GET.");
      }
      return currentAffairsResponse(ctx);
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

    for (let i = 0; i < order.length; i++) {
      const providerId = order[i];
      const isLastAttempt = i === order.length - 1;

      let upstream;
      try {
        upstream = await callProvider(providerId, bodyText, env);
      } catch (err) {
        // Network-level failure (DNS, TLS, timeout, ...) — try the next
        // provider if there is one.
        lastFailure = { status: 502, message: `${providerId}: ${err.message || "network error"}` };
        if (!isLastAttempt) continue;
        return jsonError(502, "provider_unreachable", lastFailure.message);
      }

      if (upstream.ok) {
        // Success — stream this response straight through to the client.
        // Streaming (SSE) bodies pass through untouched; Cloudflare Workers
        // proxy the ReadableStream natively, so no buffering happens here.
        const headers = new Headers(CORS_HEADERS);
        const contentType = upstream.headers.get("content-type");
        if (contentType) headers.set("Content-Type", contentType);
        headers.set("X-AI-Provider-Used", providerId);
        return new Response(upstream.body, { status: 200, headers });
      }

      // Non-2xx from this provider (bad key, rate limited, provider down, a
      // model name it doesn't recognise, ...) — capture it and, if another
      // provider is available, fall back to it instead of failing the
      // request outright.
      const text = await upstream.text().catch(() => "");
      lastFailure = { status: upstream.status, message: text || upstream.statusText };
      if (!isLastAttempt) continue;

      const debug = request.headers.get("X-Debug") === "1"
        ? { debug: debugInfo(providerId, env) }
        : {};
      return jsonError(
        upstream.status,
        "provider_error",
        lastFailure.message,
        { provider: providerId, ...debug },
      );
    }

    // Unreachable in practice (the loop always returns), but keeps the
    // function's control flow explicit.
    return jsonError(502, "unknown_error", lastFailure?.message || "All providers failed.");
    },
  async scheduled(controller, env, ctx) {
    ctx.waitUntil(refreshCurrentAffairs());
  },
};
async function currentAffairsResponse(ctx) {
  const cache = caches.default;
  const cached = await cache.match(NEWS_CACHE_KEY);
  if (cached) {
    const payload = await cached.clone().json().catch(() => null);
    if (payload && Date.now() - payload.fetchedAt < NEWS_CACHE_TTL_MS) {
      return withCors(cached);
    }
  }

  const payload = await refreshCurrentAffairs();
  const response = jsonResponse(payload);
  ctx.waitUntil(cache.put(new Request(NEWS_CACHE_KEY), response.clone()));
  return response;
}

async function refreshCurrentAffairs() {
  const settled = await Promise.allSettled(NEWS_SOURCES.map(fetchNewsSource));
  const stories = settled.flatMap((result) =>
    result.status === "fulfilled" ? result.value : []
  );
  const freshStories = filterFreshStories(deduplicateStories(stories));
  const payload = {
    fetchedAt: Date.now(),
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

async function fetchNewsSource(source) {
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
      feedType: source.feedType,
      publishedAt: validDate(publishedAt),
      excerpt: description,
      imageUrl: readImage(block),
      articleUrl: url,
    };
  }).filter(Boolean);
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

  // Relevance is used to remove low-value lifestyle/sports noise when there
  // are exam-relevant stories available. The final ordering remains strictly
  // newest-first, as required for a Latest feed.
  const scored = stories.map((story) => ({
    story,
    score: relevanceScore(story),
  }));
  const relevant = scored.filter((entry) => entry.score > 0);
  const candidates = relevant.length > 0 ? relevant : scored;

  return candidates
    .sort((a, b) => dateValue(b.story.publishedAt) - dateValue(a.story.publishedAt))
    .slice(0, 20)
    .map((entry) => entry.story);
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
  const preferredDefault = (env.DEFAULT_PROVIDER || "hcnsec").toLowerCase();
  const rest = configured.filter((id) => id !== preferredDefault);
  return configured.includes(preferredDefault)
    ? [preferredDefault, ...rest]
    : configured; // configured default provider has no key set — just try what's available
}

function providerApiKey(id, env) {
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

/** Safe-to-return diagnostics — never includes the actual key value. */
function debugInfo(providerId, env) {
  const apiKey = providerApiKey(providerId, env) || "";
  const baseUrl = providerBaseUrl(providerId, env) || "";
  return {
    targetUrl: `${baseUrl.replace(/\/+$/, "")}${CHAT_COMPLETIONS_PATH}`,
    apiKeyConfigured: apiKey.length > 0,
    apiKeyLength: apiKey.length,
    apiKeyPrefix: apiKey ? apiKey.slice(0, 5) : null,
    apiKeyHasWhitespace: /\s/.test(apiKey),
    model: providerModel(providerId, env),
  };
}

async function callProvider(id, bodyText, env) {
  if (id === "unorouter") {
    // "unorouter" is the trigger for the generic, KV-configured pool — it
    // may call UnoRouter, xKiro, or any other configured provider depending
    // on provider_config/model_config. See callDynamicPool() below.
    return callDynamicPool(bodyText, env);
  }
  const baseUrl = providerBaseUrl(id, env);
  if (!baseUrl) {
    throw new Error(`${id}: no base URL configured (set ${PROVIDERS[id].baseUrlEnv})`);
  }
  const apiKey = providerApiKey(id, env);
  const target = `${baseUrl.replace(/\/+$/, "")}${CHAT_COMPLETIONS_PATH}`;
  const outgoingBody = rewriteModel(bodyText, providerModel(id, env));

  return fetch(target, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      // Some upstream gateways reject requests that don't look like they
      // came from a normal HTTP client (Cloudflare's default fetch() sends
      // no User-Agent at all, unlike curl/browsers) — this makes the
      // forwarded request look like an ordinary client call.
      "User-Agent": "Sapiora-AI-Gateway/1.0 (+Cloudflare-Worker)",
      Authorization: `Bearer ${apiKey}`,
    },
    body: outgoingBody,
  });
}

/**
 * The generic, provider-agnostic pool. Reads provider_config + model_config
 * + policy from KV, builds an ordered, policy-filtered candidate list across
 * ALL configured providers (not just one), and tries each in turn against
 * its own base URL + secret until one responds with a 2xx (streamed
 * straight through, same as any other provider). A candidate that times
 * out, errors at the network level, has no secret configured, or returns a
 * non-2xx is not retried — the next candidate is tried immediately, up to
 * MAX_POOL_ATTEMPTS. If every candidate fails, the *last* HTTP response is
 * returned (so the caller can report a real status/message) unless every
 * attempt failed at the network level, in which case an error is thrown so
 * the outer provider loop (resolveProviderOrder) can fall back to any other
 * legacy provider configured via env vars (forge/hcnsec/etc.).
 */
async function callDynamicPool(bodyText, env) {
  const [providers, models, policy] = await Promise.all([
    getProviderConfig(env),
    getModelConfig(env),
    getPolicy(env),
  ]);

  const providerByName = new Map(
    providers.filter((p) => p.enabled !== false).map((p) => [p.name, p]),
  );

  const candidates = models
    .filter((m) => m.enabled !== false)
    .filter((m) => policy.allow_paid || m.tier !== "paid")
    .filter((m) => providerByName.has(m.provider))
    .sort((a, b) => (a.priority ?? 0) - (b.priority ?? 0))
    .slice(0, MAX_POOL_ATTEMPTS);

  if (candidates.length === 0) {
    throw new Error(
      "unorouter: no enabled model is both configured and allowed by the current free/paid policy",
    );
  }

  let lastResponse = null;
  for (const candidate of candidates) {
    const provider = providerByName.get(candidate.provider);
    const apiKey = env[provider.secretName];
    if (!apiKey) {
      console.log(
        `[ai-gateway] pool: ${provider.name}/${candidate.model} skipped (secret ${provider.secretName} not set)`,
      );
      continue;
    }

    const adapter = PROVIDER_ADAPTERS[provider.adapter || "openai"] || PROVIDER_ADAPTERS.openai;
    const target = `${provider.baseUrl.replace(/\/+$/, "")}${CHAT_COMPLETIONS_PATH}`;
    const { url, init } = adapter.buildRequest(target, apiKey, bodyText, candidate.model);

    let response;
    try {
      response = await fetchWithTimeout(url, init, MODEL_ATTEMPT_TIMEOUT_MS);
    } catch (err) {
      console.log(
        `[ai-gateway] pool: ${provider.name}/${candidate.model} failed (network/timeout), trying next`,
      );
      lastResponse = null;
      continue;
    }

    if (response.ok) {
      console.log(`[ai-gateway] pool: selected ${provider.name}/${candidate.model}`);
      return response;
    }

    console.log(
      `[ai-gateway] pool: ${provider.name}/${candidate.model} failed (status ${response.status}), trying next`,
    );
    lastResponse = response;
  }

  if (lastResponse) return lastResponse;
  console.log("[ai-gateway] pool: all candidates failed");
  throw new Error("unorouter: all pool candidates failed");
}

/**
 * Reads the list of providers the pool may use. Expected shape:
 *   { "providers": [
 *       { "name": "unorouter", "baseUrl": "...", "secretName": "UNOROUTER_API_KEY",
 *         "enabled": true, "adapter": "openai" },
 *       ...
 *   ] }
 * "adapter" is optional and defaults to "openai" (plain OpenAI-compatible
 * POST /v1/chat/completions) — see PROVIDER_ADAPTERS. Falls back to
 * DEFAULT_PROVIDER_CONFIG if the KV binding is missing, the key isn't set,
 * the value isn't valid JSON, or it contains no usable entries.
 */
async function getProviderConfig(env) {
  const kv = env.MODEL_CONFIG_KV;
  if (!kv) {
    console.log("[ai-gateway] MODEL_CONFIG_KV not bound; using default provider config");
    return DEFAULT_PROVIDER_CONFIG;
  }

  let raw;
  try {
    raw = await kv.get(PROVIDER_CONFIG_KV_KEY);
  } catch (err) {
    console.log(`[ai-gateway] provider_config read failed; using default: ${err.message || err}`);
    return DEFAULT_PROVIDER_CONFIG;
  }
  if (!raw) {
    console.log("[ai-gateway] provider_config not set; using default provider config");
    return DEFAULT_PROVIDER_CONFIG;
  }

  try {
    const parsed = JSON.parse(raw);
    const providers = Array.isArray(parsed?.providers)
      ? parsed.providers.filter(
          (p) =>
            p &&
            typeof p.name === "string" && p.name.trim() &&
            typeof p.baseUrl === "string" && p.baseUrl.trim() &&
            typeof p.secretName === "string" && p.secretName.trim(),
        )
      : [];
    if (providers.length === 0) {
      console.log("[ai-gateway] provider_config has no usable entries; using default provider config");
      return DEFAULT_PROVIDER_CONFIG;
    }
    return providers;
  } catch (err) {
    console.log(`[ai-gateway] provider_config is not valid JSON; using default: ${err.message || err}`);
    return DEFAULT_PROVIDER_CONFIG;
  }
}

/**
 * Reads the ordered list of {provider, model} candidates. Expected shape:
 *   { "models": [
 *       { "provider": "unorouter", "model": "deepseek-v4.1-flash:free",
 *         "enabled": true, "priority": 1, "tier": "free" },
 *       ...
 *   ] }
 * "enabled" defaults to true, "priority" defaults to 0 (lower runs first),
 * "tier" defaults to "free". Falls back, in order, to: the legacy
 * "model_pool" key (UnoRouter-only list from before this pool became
 * provider-agnostic, so anything already written there keeps working), then
 * DEFAULT_MODEL_CONFIG — if the KV binding is missing, "model_config" isn't
 * set, the value isn't valid JSON, or it contains no usable entries.
 */
async function getModelConfig(env) {
  const kv = env.MODEL_CONFIG_KV;
  if (!kv) {
    console.log("[ai-gateway] MODEL_CONFIG_KV not bound; using default model config");
    return DEFAULT_MODEL_CONFIG;
  }

  let raw;
  try {
    raw = await kv.get(MODEL_CONFIG_KV_KEY);
  } catch (err) {
    console.log(`[ai-gateway] model_config read failed, trying legacy key: ${err.message || err}`);
    raw = null;
  }

  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      const models = Array.isArray(parsed?.models)
        ? parsed.models
            .filter(
              (m) =>
                m &&
                typeof m.provider === "string" && m.provider.trim() &&
                typeof m.model === "string" && m.model.trim(),
            )
            .map((m) => ({
              provider: m.provider,
              model: m.model,
              enabled: m.enabled !== false,
              priority: typeof m.priority === "number" ? m.priority : 0,
              tier: m.tier === "paid" ? "paid" : "free",
            }))
        : [];
      if (models.length > 0) return models;
      console.log("[ai-gateway] model_config has no usable entries; trying legacy key");
    } catch (err) {
      console.log(`[ai-gateway] model_config is not valid JSON; trying legacy key: ${err.message || err}`);
    }
  } else {
    console.log("[ai-gateway] model_config not set; trying legacy key");
  }

  // Legacy fallback: the old UnoRouter-only { "models": ["id", ...] } shape.
  try {
    const legacyRaw = await kv.get(LEGACY_MODEL_POOL_KV_KEY);
    if (legacyRaw) {
      const parsed = JSON.parse(legacyRaw);
      const ids = Array.isArray(parsed?.models)
        ? parsed.models.filter((m) => typeof m === "string" && m.trim().length > 0)
        : [];
      if (ids.length > 0) {
        console.log("[ai-gateway] using legacy model_pool key (unorouter-only)");
        return ids.map((model, index) => ({
          provider: "unorouter",
          model,
          enabled: true,
          priority: index + 1,
          tier: "free",
        }));
      }
    }
  } catch (err) {
    console.log(`[ai-gateway] legacy model_pool read failed: ${err.message || err}`);
  }

  console.log("[ai-gateway] no usable model config found anywhere; using default model config");
  return DEFAULT_MODEL_CONFIG;
}

/**
 * Reads the global free/paid policy. Expected shape: { "allow_paid": false }.
 * Falls back to DEFAULT_POLICY (allow_paid: false — free-only) if the KV
 * binding is missing, the key isn't set, or the value isn't valid JSON. This
 * is a fail-safe default on purpose: an unreadable policy value must never
 * silently permit paid usage.
 */
async function getPolicy(env) {
  const kv = env.MODEL_CONFIG_KV;
  if (!kv) return DEFAULT_POLICY;

  let raw;
  try {
    raw = await kv.get(POLICY_KV_KEY);
  } catch (err) {
    console.log(`[ai-gateway] policy read failed; using default (free-only): ${err.message || err}`);
    return DEFAULT_POLICY;
  }
  if (!raw) return DEFAULT_POLICY;

  try {
    const parsed = JSON.parse(raw);
    return { allow_paid: parsed?.allow_paid === true };
  } catch (err) {
    console.log(`[ai-gateway] policy is not valid JSON; using default (free-only): ${err.message || err}`);
    return DEFAULT_POLICY;
  }
}

/** fetch() with a bounded timeout, so one hung model attempt can't stall
 * the whole request past a sensible limit. */
async function fetchWithTimeout(url, options, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

/** Returns [bodyText] unchanged if [model] is null, otherwise returns it
 * with the JSON "model" field replaced. Falls back to the original text on
 * any parse error — a provider getting the app's generic model value is far
 * better than the whole request failing to build. */
function rewriteModel(bodyText, model) {
  if (!model) return bodyText;
  try {
    const parsed = JSON.parse(bodyText);
    parsed.model = model;
    return JSON.stringify(parsed);
  } catch {
    return bodyText;
  }
}

function jsonError(status, code, message, extra) {
  return new Response(
    JSON.stringify({ error: { code, message, ...extra } }),
    {
      status,
      headers: { "Content-Type": "application/json", ...CORS_HEADERS },
    },
  );
}

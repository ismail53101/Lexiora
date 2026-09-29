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
 * Provider selection: this is a HINT used only to order the fallback chain
 * AFTER the dynamic pool (see below) — it no longer picks a single provider
 * outright.
 *   1. HTTP header  X-AI-Provider: forge | hcnsec | tokenrouter | openrouter | unorouter | auto
 *   2. JSON body    { "provider": "forge" | "hcnsec" | "tokenrouter" | "openrouter" | "unorouter" | "auto" }
 *   3. env.DEFAULT_PROVIDER (falls back to "hcnsec" if unset)
 *
 * For every request to this endpoint, the remotely-configured, KV-driven
 * pool ("unorouter" — see below) is tried FIRST, regardless of which of the
 * above was sent. Only if the whole pool fails does the Worker fall back
 * through the legacy env-var-configured providers (forge/hcnsec/tokenrouter/
 * openrouter), trying the one named above first (if configured) and then
 * every other configured one, in a deterministic order — the same
 * "keep trying until something works" fallback "auto" has always had, just
 * reordered so an explicit request/DEFAULT_PROVIDER value no longer bypasses
 * the pool. See resolveProviderOrder() for the exact precedence. Once a
 * provider's response has started streaming to the client, the response is
 * never switched mid-stream (that's not a meaningful retry point for an
 * OpenAI-compatible proxy).
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

/**
 * Joins a provider's configured base URL with the OpenAI-compatible chat-
 * completions path, without ever producing a duplicated "/v1" segment.
 *
 * ROOT CAUSE (xKiro HTTP 400): xKiro's provider_config entry is configured
 * with baseUrl "https://api.xkiro.com/v1" (xKiro's real, documented base
 * URL already includes "/v1"). Naively appending CHAT_COMPLETIONS_PATH
 * ("/v1/chat/completions") — which every call site used to do — produced
 * ".../v1/v1/chat/completions", a route xKiro doesn't serve. Other
 * providers (UnoRouter, HCNSEC, Forge, ...) are configured WITHOUT a
 * trailing "/v1" and rely on CHAT_COMPLETIONS_PATH supplying it, which is
 * why they kept working. This helper handles both conventions correctly —
 * it's not xKiro-specific, so any future provider configured either way
 * (with or without a trailing "/v1" in its baseUrl) resolves to the right
 * URL without another code change.
 */
function joinChatCompletionsUrl(baseUrl) {
  const trimmed = baseUrl.replace(/\/+$/, "");
  if (trimmed.endsWith(CHAT_COMPLETIONS_PATH)) return trimmed;
  return /\/v1$/i.test(trimmed)
    ? `${trimmed}${CHAT_COMPLETIONS_PATH.slice(3)}` // baseUrl already ends in "/v1" — don't add a second one
    : `${trimmed}${CHAT_COMPLETIONS_PATH}`;
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

// ── GNews (Current Affairs) ────────────────────────────────────────────────
// Deliberately NOT part of NEWS_SOURCES: those entries are RSS feeds fetched
// and parsed as XML. GNews is a JSON API with its own quota-protected,
// KV-snapshot-backed fetch path (see fetchGNewsStories()).
//
// Each feed is fully independent: its own endpoint params, its own KV
// snapshot, and a category fixed here — an article's category is decided by
// the feed that returned it, never inferred from its content.
const GNEWS_TOP_HEADLINES_URL = "https://gnews.io/api/v4/top-headlines";

// Pakistan feed search query (GNews OR-syntax, well under its 200-char limit).
// Deliberately concise: country/province/city names only; "Pakistan government"
// and "Baltistan" are covered by "Pakistan" and "Gilgit".
const GNEWS_PAKISTAN_QUERY =
  'Pakistan OR Pakistani OR Islamabad OR Karachi OR Lahore OR Peshawar OR Quetta OR Rawalpindi OR Balochistan OR Sindh OR Punjab OR "Khyber Pakhtunkhwa" OR Gilgit';

// Strong Pakistan signals: country, cities, provinces/regions and
// Pakistan-specific institutions that are unambiguous on their own. People
// are deliberately NOT listed (an incidental mention of a Pakistani person is
// not a Pakistan story). "Punjab" is handled separately (Indian Punjab).
const PAKISTAN_STRONG_SIGNAL = new RegExp(
  "\\b(?:pakistan(?:i|is)?|islamabad|karachi|lahore|peshawar|quetta|rawalpindi|" +
  "faisalabad|multan|gwadar|sialkot|abbottabad|balochistan|baluchistan|sindh|" +
  "khyber[\\s-]+pakhtunkhwa|gilgit|baltistan|azad\\s+(?:jammu\\s+and\\s+)?kashmir|" +
  "waziristan|ispr|nadra|pml-?n|pml-?q)\\b",
  "gi",
);
const PAKISTAN_PUNJAB_SIGNAL = /\bpunjab\b/gi;
// Context that means Punjab is the Indian state; suppresses the Punjab-only
// signal. Deliberately limited to specific Indian-Punjab locators (cities,
// neighbouring Indian states, BSF, Indian parties/teams/banks, explicit
// phrases). Generic words such as "India", "Indian" or "Sikh" are NOT listed:
// they also appear in genuine Pakistani-Punjab stories ("Punjab water dispute
// with India", Nankana Sahib / Kartarpur pilgrim coverage).
const INDIAN_PUNJAB_CONTEXT = new RegExp(
  "\\b(?:indian\\s+punjab|punjab,?\\s*\\(?india|india'?s\\s+punjab|punjab\\s+border|" +
  "amritsar|chandigarh|ludhiana|jalandhar|patiala|mohali|bathinda|pathankot|gurdaspur|sangrur|" +
  "haryana|himachal|punjab\\s+kings|punjab\\s+national\\s+bank|bhagwant\\s+mann|akali|" +
  "bsf|border\\s+security\\s+force)\\b",
  "i",
);
// A description-only signal must appear in the lead of the description.
const PAKISTAN_LEAD_CHARS = 160;

function countMatches(regex, text) {
  regex.lastIndex = 0;
  const found = text.match(regex);
  regex.lastIndex = 0;
  return found ? found.length : 0;
}

/**
 * Server-side relevance guard for the GNews Pakistan feed. True only when the
 * article's own title/description carries a strong Pakistan signal:
 *   - a signal in the title, or
 *   - a signal in the lead (first ~160 chars) of the description, or
 *   - two or more signals anywhere in the description.
 * A lone, late description mention ("... as India, Pakistan and others ...")
 * is treated as incidental and rejected. Publisher/source never counts.
 * "Punjab" alone counts only when there is no Indian-Punjab context.
 */
function isPakistanRelevant(title, description) {
  const t = typeof title === "string" ? title : "";
  const d = typeof description === "string" ? description : "";
  const strongIn = (text) => countMatches(PAKISTAN_STRONG_SIGNAL, text);
  const punjabIn = (text) =>
    INDIAN_PUNJAB_CONTEXT.test(t + " " + d) ? 0 : countMatches(PAKISTAN_PUNJAB_SIGNAL, text);
  const signals = (text) => strongIn(text) + punjabIn(text);

  if (signals(t) > 0) return true;
  if (signals(d.slice(0, PAKISTAN_LEAD_CHARS)) > 0) return true;
  return signals(d) >= 2;
}

/**
 * True for a story that came from the guarded Pakistan GNews feed. Stories
 * carry no extra field for this, so it is derived from what the feed fixes:
 * feedType "gnews" + category "National" (RSS feedTypes are "Latest News" /
 * "Opinions"; World GNews is "International"). The guard is re-checked so
 * only genuinely Pakistan-relevant stories are ever treated specially.
 */
function isPakistanGNewsStory(story) {
  return story.feedType === "gnews" && story.category === "National" &&
    isPakistanRelevant(story.title, story.excerpt);
}
const GNEWS_FEEDS = [
  {
    id: "gnews-pakistan",
    name: "GNews",
    category: "National",
    feedType: "gnews",
    // v2: the v1 snapshot was built from an unfiltered country=pk request and
    // contains off-topic (non-Pakistan) articles. A fresh key guarantees they
    // are never served from the fresh-snapshot, backoff or failure-fallback paths.
    snapshotKey: "gnews:pakistan:v2",
    // q makes GNews search for Pakistan content explicitly; country=pk alone
    // only means "Pakistani publisher". pakistanGuard additionally enforces
    // the server-side relevance check (see isPakistanRelevant()).
    params: { country: "pk", lang: "en", q: GNEWS_PAKISTAN_QUERY },
    pakistanGuard: true,
  },
  {
    id: "gnews-world",
    name: "GNews",
    category: "International",
    feedType: "gnews",
    snapshotKey: "gnews:world:v1",
    params: { category: "world", lang: "en" },
  },
];
// GNews Free plan is ~100 requests/day. One request per feed per hour is
// 48/day for both feeds combined, regardless of how often the 15-minute cron
// or user traffic runs.
const GNEWS_SNAPSHOT_TTL_MS = 60 * 60 * 1000;
// After a failed request (429, other HTTP error, timeout, bad body) don't
// retry until this has passed, so a failing GNews can't be hammered by the
// 15-minute cron or by cache-miss traffic.
const GNEWS_FAILURE_BACKOFF_MS = 30 * 60 * 1000;
const GNEWS_REQUEST_TIMEOUT_MS = 10000;
// GNews Free plan: 1 request/second; concurrent requests get HTTP 429. Real
// GNews requests (never snapshot hits) are therefore spaced at least this far
// apart. gnewsNextSlotAt is the earliest time the next request may be sent.
const GNEWS_MIN_REQUEST_GAP_MS = 1100;
let gnewsNextSlotAt = 0;
const GNEWS_MAX_ARTICLES = 10; // free-plan per-request maximum
// The last valid snapshot is kept this long as a fallback for GNews outages.
// (Stale stories are still removed by the existing 48h freshness filter.)
const GNEWS_SNAPSHOT_KV_EXPIRATION_S = 7 * 24 * 60 * 60;

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
    // Worker itself defines, completely separate from the real Forge/HCNSEC/
    // xKiro keys. Without it, anyone who finds the Worker's URL could rack up
    // usage on your real provider accounts.
    //
    // FIX: env.WORKER_SHARED_KEY is now trimmed before comparison. A secret
    // set via `wrangler secret put` from a piped/redirected input on Windows
    // PowerShell (e.g. `... | wrangler secret put WORKER_SHARED_KEY`, or
    // pasting into the interactive prompt from a source that appended a
    // trailing newline) can end up with a trailing "\r" or "\n" character
    // baked into the stored secret value. That character is invisible when
    // you look at the key, but it makes `token !== env.WORKER_SHARED_KEY`
    // fail for every single request — including one built with the exact,
    // correct key — because the header token (already `.trim()`ed below) no
    // longer matches the untrimmed secret. This was the previous code's only
    // gap: it trimmed the token extracted from the header, but never trimmed
    // the secret value it was compared against.
    const sharedKey = (env.WORKER_SHARED_KEY || "").trim();
    if (sharedKey) {
      const auth = request.headers.get("Authorization") || "";
      const token = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
      if (token !== sharedKey) {
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
    ctx.waitUntil(refreshCurrentAffairs(env));
  },
};
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
  // RSS and GNews run in parallel. fetchGNewsStories() never throws, so a
  // GNews problem can never break the RSS feed.
  const [settled, gnewsStories] = await Promise.all([
    Promise.allSettled(NEWS_SOURCES.map(fetchNewsSource)),
    fetchGNewsStories(env),
  ]);
  const stories = [
    ...settled.flatMap((result) =>
      result.status === "fulfilled" ? result.value : []
    ),
    ...gnewsStories,
  ];
  const freshStories = filterFreshStories(deduplicateStories(stories));
  const payload = {
    fetchedAt: Date.now(),
    national: selectLatestStories(
      freshStories.filter((story) => story.category === "National"),
    ),
    international: selectLatestStories(
      freshStories.filter((story) => story.category === "International"),
    ),
    sources: [
      ...NEWS_SOURCES,
      ...(gnewsEnabled(env) ? GNEWS_FEEDS : []),
    ].map(({ id, name, category, feedType }) => ({
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

/**
 * GNews is used only when BOTH the secret (env.GNEWS_API_KEY) and the
 * dedicated snapshot KV (env.NEWS_CACHE_KV) exist. Without the KV there'd be
 * no way to protect the daily quota (every 15-minute cron run and every
 * location's cache miss would call GNews), so in that case GNews is skipped
 * entirely and the RSS feed carries on alone.
 */
function gnewsEnabled(env) {
  return Boolean(env && env.GNEWS_API_KEY && env.NEWS_CACHE_KV);
}

/**
 * Returns story objects (existing story schema) from every GNews feed. Never
 * throws. The two feeds are independent: each has its own snapshot, TTL,
 * backoff and failure handling.
 */
async function fetchGNewsStories(env) {
  if (!gnewsEnabled(env)) {
    if (env && env.GNEWS_API_KEY && !env.NEWS_CACHE_KV) {
      console.log("[current-affairs] gnews skipped: NEWS_CACHE_KV is not bound");
    }
    return [];
  }
  // Sequential on purpose (see GNEWS_MIN_REQUEST_GAP_MS): the feeds are still
  // fully independent — each has its own snapshot, TTL, backoff and failure
  // handling, and one feed failing never stops the next.
  const results = [];
  for (const feed of GNEWS_FEEDS) {
    try {
      results.push(await getGNewsFeedStories(feed, env));
    } catch {
      // Deliberately logs no error text: keep anything URL/key-shaped out.
      console.log(`[current-affairs] ${feed.snapshotKey} unexpected failure`);
      results.push([]);
    }
  }
  return results.flat();
}

/**
 * Quota protection lives here. Order of checks:
 *   1. snapshot younger than GNEWS_SNAPSHOT_TTL_MS      -> reuse, NO GNews call
 *   2. a recent failure and still inside its backoff   -> reuse, NO GNews call
 *   3. otherwise request GNews once:
 *        success -> save new snapshot
 *        failure -> keep last valid snapshot (if any), start backoff
 */
async function getGNewsFeedStories(feed, env) {
  const now = Date.now();
  const snapshot = await readGNewsSnapshot(env.NEWS_CACHE_KV, feed);

  if (snapshot && snapshot.fetchedAt > 0 && now - snapshot.fetchedAt < GNEWS_SNAPSHOT_TTL_MS) {
    console.log(`[current-affairs] ${feed.snapshotKey} snapshot fresh; GNews not called`);
    return snapshot.articles;
  }
  if (snapshot && snapshot.nextAttemptAt > now) {
    console.log(`[current-affairs] ${feed.snapshotKey} in failure backoff; GNews not called`);
    return snapshot.articles;
  }

  const result = await requestGNewsFeed(feed, env);
  if (result.ok) {
    // Pakistan only (World never enters this block): a successful request whose
    // articles were all removed by the relevance guard must not wipe a good
    // snapshot. Keep the previous articles and start the normal failure
    // backoff (same shape as the failure path below) so the 15-minute cron
    // can't re-request GNews and burn quota.
    if (feed.pakistanGuard && result.articles.length === 0 &&
        snapshot && snapshot.articles.length > 0) {
      console.log(`[current-affairs] ${feed.snapshotKey} 0 relevant articles; keeping last snapshot`);
      await writeGNewsSnapshot(env.NEWS_CACHE_KV, feed, {
        fetchedAt: snapshot.fetchedAt,
        nextAttemptAt: now + GNEWS_FAILURE_BACKOFF_MS,
        articles: snapshot.articles,
      });
      return snapshot.articles;
    }
    await writeGNewsSnapshot(env.NEWS_CACHE_KV, feed, {
      fetchedAt: now,
      nextAttemptAt: 0,
      articles: result.articles,
    });
    console.log(`[current-affairs] ${feed.snapshotKey} refreshed (${result.articles.length} articles)`);
    return result.articles;
  }

  console.log(`[current-affairs] ${feed.snapshotKey} GNews failed (${result.reason}); using ${snapshot ? "last snapshot" : "no data"}`);
  await writeGNewsSnapshot(env.NEWS_CACHE_KV, feed, {
    fetchedAt: snapshot ? snapshot.fetchedAt : 0,
    nextAttemptAt: now + GNEWS_FAILURE_BACKOFF_MS,
    articles: snapshot ? snapshot.articles : [],
  });
  return snapshot ? snapshot.articles : [];
}

/**
 * One GNews request. Never throws and never logs the URL (it carries the API
 * key) or any error text. Returns { ok: true, articles } or
 * { ok: false, reason } where reason is a short, key-free label.
 */
async function requestGNewsFeed(feed, env) {
  const url = new URL(GNEWS_TOP_HEADLINES_URL);
  for (const [key, value] of Object.entries(feed.params)) {
    url.searchParams.set(key, value);
  }
  url.searchParams.set("max", String(GNEWS_MAX_ARTICLES));
  url.searchParams.set("apikey", env.GNEWS_API_KEY);

  // Rate-limit spacing. Only reached when a real GNews request is about to be
  // made (fresh snapshots / backoff return earlier and never wait). The slot
  // is reserved synchronously, so even two overlapping refreshes in the same
  // isolate end up at least GNEWS_MIN_REQUEST_GAP_MS apart.
  const startAt = Math.max(Date.now(), gnewsNextSlotAt);
  gnewsNextSlotAt = startAt + GNEWS_MIN_REQUEST_GAP_MS;
  const waitMs = startAt - Date.now();
  if (waitMs > 0) await new Promise((resolve) => setTimeout(resolve, waitMs));

  let response;
  try {
    response = await fetchWithTimeout(
      url.toString(),
      {
        headers: {
          Accept: "application/json",
          "User-Agent": "Sapiora-Current-Affairs/1.0 (+GNews)",
        },
      },
      GNEWS_REQUEST_TIMEOUT_MS,
    );
  } catch {
    return { ok: false, reason: "network/timeout" };
  } finally {
    // Measure the gap from when this request finished too, so a slow response
    // can't shrink the spacing seen by GNews.
    gnewsNextSlotAt = Math.max(gnewsNextSlotAt, Date.now() + GNEWS_MIN_REQUEST_GAP_MS);
  }

  if (!response.ok) {
    return { ok: false, reason: `http ${response.status}` };
  }

  let data;
  try {
    data = await response.json();
  } catch {
    return { ok: false, reason: "invalid json" };
  }
  if (!data || !Array.isArray(data.articles)) {
    return { ok: false, reason: "unexpected body" };
  }

  const mapped = data.articles
    .map((article) => mapGNewsArticle(article, feed))
    .filter(Boolean);
  // Only feeds that opt in (Pakistan) are filtered; World is returned as-is.
  const articles = feed.pakistanGuard
    ? mapped.filter((story) => isPakistanRelevant(story.title, story.excerpt))
    : mapped;
  if (feed.pakistanGuard) {
    console.log(`[current-affairs] ${feed.snapshotKey} relevance guard kept ${articles.length}/${mapped.length}`);
  }
  return { ok: true, articles };
}

/** GNews article -> the existing story schema. Category comes from the feed. */
function mapGNewsArticle(article, feed) {
  if (!article || typeof article !== "object") return null;
  const title = typeof article.title === "string" ? cleanText(article.title) : "";
  const articleUrl = httpUrlOrNull(article.url);
  if (!title || !articleUrl) return null;
  return {
    id: stableStoryId(articleUrl, title),
    title,
    source:
      typeof article.source?.name === "string" && article.source.name.trim()
        ? article.source.name.trim()
        : feed.name,
    category: feed.category,
    feedType: feed.feedType,
    publishedAt: validDate(article.publishedAt),
    excerpt: typeof article.description === "string"
      ? cleanText(article.description).slice(0, 500)
      : "",
    imageUrl: httpUrlOrNull(article.image),
    articleUrl,
  };
}

function httpUrlOrNull(value) {
  if (typeof value !== "string") return null;
  try {
    const parsed = new URL(value.trim());
    return parsed.protocol === "https:" || parsed.protocol === "http:"
      ? parsed.toString()
      : null;
  } catch {
    return null;
  }
}

/** Reads and validates a snapshot. Returns null if absent/unreadable/invalid. */
async function readGNewsSnapshot(kv, feed) {
  let raw;
  try {
    raw = await kv.get(feed.snapshotKey);
  } catch {
    console.log(`[current-affairs] ${feed.snapshotKey} snapshot read failed`);
    return null;
  }
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw);
    if (!parsed || !Array.isArray(parsed.articles)) return null;
    return {
      fetchedAt: Number(parsed.fetchedAt) || 0,
      nextAttemptAt: Number(parsed.nextAttemptAt) || 0,
      // Category is re-applied from the feed on every read, so a snapshot can
      // never leak a story into the wrong list.
      articles: parsed.articles
        .filter((a) => a && typeof a === "object" && a.title && a.articleUrl)
        .map((a) => ({ ...a, category: feed.category, feedType: feed.feedType })),
    };
  } catch {
    return null;
  }
}

async function writeGNewsSnapshot(kv, feed, snapshot) {
  try {
    await kv.put(feed.snapshotKey, JSON.stringify(snapshot), {
      expirationTtl: GNEWS_SNAPSHOT_KV_EXPIRATION_S,
    });
  } catch {
    console.log(`[current-affairs] ${feed.snapshotKey} snapshot write failed`);
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
  // Guarded Pakistan GNews stories that score exactly 0 (neutral, e.g. "Karachi
  // receives heavy rainfall") are kept alongside the positive-score stories.
  // Negative scores (sports/entertainment noise) are still dropped, and when
  // nothing scores above 0 the original keep-everything fallback is unchanged.
  const candidates = relevant.length > 0
    ? scored.filter((entry) =>
        entry.score > 0 || (entry.score === 0 && isPakistanGNewsStory(entry.story)))
    : scored;

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
 * Builds the ordered list of providers to try for a normal AI Assistant
 * chat request.
 *
 * FIX: previously, any explicitly *requested* provider (X-AI-Provider
 * header, body "provider" field, or DEFAULT_PROVIDER) was tried ALONE, with
 * no fallback — including "unorouter" itself only ever being reached when
 * nothing else was requested (i.e. only on the "auto" path). Since the
 * deployed Sapiora app sends a fixed "X-AI-Provider: hcnsec" header on every
 * normal chat request (a leftover default from before the KV-configured
 * pool existed), that meant the remotely-configured pool
 * (provider_config/model_config/policy in MODEL_CONFIG_KV — which may route
 * to UnoRouter, xKiro, or any future KV-configured provider) was never even
 * attempted for real app traffic, no matter what was in KV.
 *
 * New priority for the normal chat route: dynamic pool ("unorouter") >
 * explicitly-requested legacy provider (header/body/DEFAULT_PROVIDER) >
 * every other configured legacy provider. The pool is tried first
 * unconditionally; only if it fails entirely (see callDynamicPool()) does
 * the existing legacy-provider fallback chain run, in the same cascading
 * style "auto" has always used — just reordered so the caller's explicit
 * preference (if any) leads that chain instead of always DEFAULT_PROVIDER.
 * An explicit request for "unorouter" or "auto" is unaffected — both already
 * meant "try the pool" before this fix.
 *
 * "unorouter" is included unconditionally, independent of whether
 * UNOROUTER_API_KEY is set: the pool's real providers/secrets now come from
 * provider_config in KV (e.g. XKIRO_API_KEY for the xKiro entry), so an
 * env-var gate on the literal "unorouter" id would make the pool
 * non-authoritative again exactly as this fix is meant to prevent. The
 * legacy per-provider secret check below (providerApiKey) still applies
 * only to the header-selectable legacy providers (hcnsec/forge/tokenrouter/
 * openrouter), unchanged.
 */
function resolveProviderOrder(requested, env) {
  const configuredLegacy = Object.keys(PROVIDERS).filter(
    (id) => id !== "unorouter" && providerApiKey(id, env),
  );

  const preferredLegacyDefault = (env.DEFAULT_PROVIDER || "hcnsec").toLowerCase();
  const isExplicitLegacyRequest =
    requested !== "auto" && requested !== "unorouter" && configuredLegacy.includes(requested);

  const legacyFallbackChain = isExplicitLegacyRequest
    ? [requested, ...configuredLegacy.filter((id) => id !== requested)]
    : configuredLegacy.includes(preferredLegacyDefault)
    ? [preferredLegacyDefault, ...configuredLegacy.filter((id) => id !== preferredLegacyDefault)]
    : configuredLegacy; // no configured provider matches the preference — just try what's available

  return ["unorouter", ...legacyFallbackChain];
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
    targetUrl: joinChatCompletionsUrl(baseUrl),
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
  const target = joinChatCompletionsUrl(baseUrl);
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
    const target = joinChatCompletionsUrl(provider.baseUrl);
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
    if (provider.name.toLowerCase() === "xkiro") {
      // TEMPORARY DIAGNOSTIC ONLY — see logXkiroDebug() below. Remove once
      // the xKiro HTTP 400s are diagnosed.
      await logXkiroDebug(response);
    }
    lastResponse = response;
  }

  if (lastResponse) return lastResponse;
  console.log("[ai-gateway] pool: all candidates failed");
  throw new Error("unorouter: all pool candidates failed");
}

/**
 * TEMPORARY DIAGNOSTIC ONLY (xKiro HTTP 400 investigation) — logs a safe
 * summary of a failed xKiro response so the cause can be found. Does NOT
 * change routing, fallback, or what's returned to the caller: it reads a
 * CLONED response, so the original (used for the existing fallback /
 * error-reporting logic) is left completely untouched.
 *
 * Security: never logs XKIRO_API_KEY, the Authorization header, request
 * messages/prompts/conversation history, or the full response body.
 * Extracts only error.message/error.type/error.code when present; otherwise
 * logs a truncated (max 500 char) body with any Authorization/Bearer-token-
 * shaped text redacted first, as a last resort.
 *
 * Remove this function and its one call site once the 400s are diagnosed.
 */
async function logXkiroDebug(response) {
  let raw;
  try {
    raw = await response.clone().text();
  } catch (err) {
    console.log(`[xkiro-debug] status=${response.status} (could not read response body)`);
    return;
  }

  try {
    const parsed = JSON.parse(raw);
    const err = parsed && typeof parsed === "object" ? parsed.error : null;
    if (err && typeof err === "object") {
      const safe = {};
      if (typeof err.message === "string") safe.message = err.message;
      if (typeof err.type === "string") safe.type = err.type;
      if (typeof err.code === "string" || typeof err.code === "number") safe.code = err.code;
      if (Object.keys(safe).length > 0) {
        console.log(`[xkiro-debug] status=${response.status} error=${JSON.stringify(safe)}`);
        return;
      }
    }
  } catch {
    // Not JSON (or no usable error.* fields) — fall through to the
    // redacted-and-truncated raw-body log below.
  }

  const redacted = raw
    .replace(/"authorization"\s*:\s*"[^"]*"/gi, '"authorization":"[REDACTED]"')
    .replace(/bearer\s+\S+/gi, "Bearer [REDACTED]")
    .slice(0, 500);
  console.log(`[xkiro-debug] status=${response.status} body(truncated, redacted)=${redacted}`);
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

/** Returns [bodyText] with the gateway-only "provider" field removed and,
 * if [model] is given, the JSON "model" field replaced with it.
 *
 * ROOT CAUSE (xKiro HTTP 400, contributing factor): "provider" is a
 * Sapiora/Worker-only routing hint read by pickRequestedProvider() — it was
 * never part of the OpenAI-compatible chat-completions schema, but this
 * function previously only ever touched "model", so "provider" was forwarded
 * upstream unchanged on every request. Some upstream providers (xKiro) apply
 * stricter schema validation and reject a request containing an unrecognized
 * top-level field with HTTP 400; others (UnoRouter) are lenient about it,
 * which is why this went unnoticed there. It is now always stripped, for
 * every provider, regardless of whether [model] is also being rewritten.
 * Falls back to the original text unchanged on any parse error — a provider
 * getting the raw app request (including "provider") is far better than the
 * whole request failing to build. */
function rewriteModel(bodyText, model) {
  let parsed;
  try {
    parsed = JSON.parse(bodyText);
  } catch {
    return bodyText;
  }
  if (parsed && typeof parsed === "object" && "provider" in parsed) {
    delete parsed.provider;
  }
  if (model) {
    parsed.model = model;
  }
  return JSON.stringify(parsed);
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

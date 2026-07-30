/**
 * Sapiora AI Assistant gateway.
 *
 * The Flutter app talks ONLY to this Worker (SAPIORA_AI_BASE_URL points
 * here). This Worker holds the real Forge AI / HCNSEC credentials as
 * Worker secrets and is the only thing that ever calls them — neither key
 * exists in the app, in git, or in any client-visible place.
 *
 * Endpoint:  POST /v1/chat/completions   (OpenAI-compatible body)
 *
 * Provider selection (checked in this order — first one present wins):
 *   1. HTTP header  X-AI-Provider: forge | hcnsec | auto
 *   2. JSON body    { "provider": "forge" | "hcnsec" | "auto" }
 *   3. env.DEFAULT_PROVIDER (falls back to "hcnsec" if unset)
 *
 * "auto" (the app's default) tries the default provider first and — only if
 * that attempt fails before any response body has been sent to the client
 * (connection error, timeout, or a non-2xx status) — automatically retries
 * with the other provider. Once a provider's response has started streaming
 * to the client, the response is never switched mid-stream (that's not a
 * meaningful retry point, and matches how every other OpenAI-compatible
 * proxy behaves).
 *
 * ── Adding a new provider later ────────────────────────────────────────────
 * 1. Add its base URL + secret name to PROVIDERS below.
 * 2. Set the secret with `wrangler secret put <NAME>_API_KEY`.
 * 3. Nothing else changes — not the Flutter app, not this routing logic.
 */

/** @type {Record<string, { baseUrlEnv: string, apiKeyEnv: string, defaultBaseUrl?: string }>} */
const PROVIDERS = {
  forge: { baseUrlEnv: "FORGE_BASE_URL", apiKeyEnv: "FORGE_API_KEY" },
  hcnsec: {
    baseUrlEnv: "HCNSEC_BASE_URL",
    apiKeyEnv: "HCNSEC_API_KEY",
    defaultBaseUrl: "https://api.hcnsec.cn",
  },
};

const CHAT_COMPLETIONS_PATH = "/v1/chat/completions";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-AI-Provider",
};

export default {
  /**
   * @param {Request} request
   * @param {Record<string, string>} env
   */
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
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
};

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
  };
}

async function callProvider(id, bodyText, env) {
  const baseUrl = providerBaseUrl(id, env);
  if (!baseUrl) {
    throw new Error(`${id}: no base URL configured (set ${PROVIDERS[id].baseUrlEnv})`);
  }
  const apiKey = providerApiKey(id, env);
  const target = `${baseUrl.replace(/\/+$/, "")}${CHAT_COMPLETIONS_PATH}`;

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
    body: bodyText,
  });
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

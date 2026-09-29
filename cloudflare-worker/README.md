# Sapiora AI gateway (Cloudflare Worker)

Routes the app's AI Assistant requests to **Forge AI**, **HCNSEC**, or **OpenRouter**, or lets
the Worker pick automatically with fallback. The app only ever talks to this
Worker — it never sees, sends, or stores any provider's real API key.

## Deploy

```bash
cd cloudflare-worker
npm install -g wrangler   # if you don't have it already
wrangler login
wrangler deploy
```

This publishes the Worker at `https://sapiora-ai-worker.<your-subdomain>.workers.dev`
(or your existing URL, if you're redeploying to the same Worker name).

## Configure secrets (never commit these — set them directly in Cloudflare)

```bash
# The real upstream provider keys:
wrangler secret put FORGE_API_KEY
wrangler secret put HCNSEC_API_KEY
wrangler secret put OPENROUTER_API_KEY
# Optional model override; defaults to stealth/ox-alpha.
wrangler secret put OPENROUTER_MODEL

# The key the *app* authenticates with (this is what goes into the
# SAPIORA_AI_API_KEY GitHub secret — NOT either provider's real key):
wrangler secret put WORKER_SHARED_KEY
```

You can also set/verify secrets from the Cloudflare dashboard:
**Workers & Pages → your Worker → Settings → Variables and Secrets**.

If Forge AI's base URL isn't `https://api.hcnsec.cn`-style default, set it:

```bash
wrangler secret put FORGE_BASE_URL
# or add it as a plain var in wrangler.toml if it's not sensitive
```

## Wire it into the app

In GitHub → **Settings → Secrets and variables → Actions**:

| Secret | Value |
|---|---|
| `SAPIORA_AI_BASE_URL` | Your Worker's URL, e.g. `https://sapiora-ai-worker.<subdomain>.workers.dev` |
| `SAPIORA_AI_API_KEY` | The `WORKER_SHARED_KEY` value you set above |
| `SAPIORA_AI_PROVIDER` *(optional)* | `auto` (default), `forge`, `hcnsec`, or `openrouter` — normally leave unset |

## Test it directly

```bash
curl -N https://YOUR_WORKER_URL/v1/chat/completions \
  -H "Authorization: Bearer YOUR_WORKER_SHARED_KEY" \
  -H "Content-Type: application/json" \
  -H "X-AI-Provider: auto" \
  -d '{
    "model": "auto",
    "stream": true,
    "messages": [{"role": "user", "content": "Say hello in one sentence."}]
  }'
```

You should see a stream of `data: {...}` lines ending in `data: [DONE]`.

Try forcing a specific provider with `-H "X-AI-Provider: forge"`,
`-H "X-AI-Provider: hcnsec"`, or `-H "X-AI-Provider: openrouter"` to test each one individually.

## Testing checklist

- [ ] `auto` with both provider keys set → succeeds via the default provider
- [ ] `auto` with the default provider's key deliberately wrong → automatically
      falls back to the other provider and still succeeds
- [ ] Explicit `X-AI-Provider: forge` → only calls Forge (fails if its key is wrong,
      does *not* silently fall back to HCNSEC)
- [ ] Explicit `X-AI-Provider: hcnsec` → only calls HCNSEC
- [ ] Explicit `X-AI-Provider: openrouter` → only calls OpenRouter with `OPENROUTER_MODEL` or `stealth/ox-alpha`
- [ ] Missing/invalid `Authorization` header → `401` from the Worker itself,
      before either provider is ever called
- [ ] Streaming works end-to-end in the app (tokens appear incrementally, not
      all at once at the end)
- [ ] Stopping generation mid-reply in the app still works (client-side
      cancellation — unchanged, the Worker doesn't need to know)
- [ ] Both providers down/misconfigured → app shows a normal error, not a crash

## Provider configuration

For OpenRouter, use `OPENROUTER_API_KEY` as the Cloudflare Worker secret. The default upstream is `https://openrouter.ai/api/v1` and the default model is `stealth/ox-alpha`; set `OPENROUTER_MODEL` only when you want a different OpenRouter model. Set `DEFAULT_PROVIDER=openrouter` for OpenRouter-first automatic routing, or send `X-AI-Provider: openrouter` for an explicit request. Keep `DEFAULT_PROVIDER=auto` to retain automatic fallback across all configured providers.

## Adding a legacy, header-selectable provider later (e.g. Gemini, Claude, Groq, ...)

This is for a provider you want reachable by name via `X-AI-Provider: <name>`,
calling one fixed model. For the free-model pool that adds providers with
*zero* code changes, see "The remotely-configured, provider-agnostic AI
pool" below instead — that's almost always what you want for a new free
provider.

1. In `worker.js`, add an entry to the `PROVIDERS` map with its base-URL env
   var name and API-key env var name. If it needs a specific model id rather
   than whatever the app sent, also add `modelEnv`/`defaultModel` — see the
   `tokenrouter` entry for an example (routes to `moonshotai/kimi-k3-free`).
2. `wrangler secret put <NEWPROVIDER>_API_KEY`.
3. Optionally set `<NEWPROVIDER>_BASE_URL` if it's not OpenAI-compatible at
   the default path.
4. Deploy: `wrangler deploy`.

Nothing in the Flutter app changes — it already just sends `X-AI-Provider`
as a hint and lets the Worker do the rest.

## The remotely-configured, provider-agnostic AI pool

Selecting `unorouter` (via `X-AI-Provider: unorouter`, `DEFAULT_PROVIDER`, or
letting `auto` reach it) doesn't call one fixed provider — it runs a pool of
`{provider, model}` candidates read from Cloudflare KV (binding
`MODEL_CONFIG_KV`, same namespace as before) and tries them in priority
order until one succeeds. UnoRouter and xKiro below are just two entries in
that pool, not special cases in the code — adding, removing, or replacing a
free provider or model is a KV write, not a Worker deploy, and never
requires a Flutter change or a new APK/AAB build.

Three KV keys drive it, all plain JSON values:

### `provider_config` — which providers exist

```json
{
  "providers": [
    {
      "name": "unorouter",
      "baseUrl": "https://api.unorouter.com",
      "secretName": "UNOROUTER_API_KEY",
      "enabled": true,
      "adapter": "openai"
    },
    {
      "name": "xkiro",
      "baseUrl": "https://api.xkiro.com",
      "secretName": "XKIRO_API_KEY",
      "enabled": true,
      "adapter": "openai"
    }
  ]
}
```

- `name` — an id you choose; referenced by `model_config` entries below.
- `baseUrl` — the provider's OpenAI-compatible base URL (`/v1/chat/completions`
  is appended automatically).
- `secretName` — the **name** of the Worker Secret holding that provider's
  real API key (set with `wrangler secret put <secretName>`). The Worker
  reads `env[secretName]` at request time — the key itself is never in this
  JSON, in KV, in git, or anywhere Flutter can see it.
- `enabled` — set `false` to take a provider out of rotation without
  deleting its entry.
- `adapter` — optional, defaults to `"openai"` (plain OpenAI-compatible
  request/response). Only needed for a provider that isn't fully
  OpenAI-compatible — see "Adding a provider that isn't fully
  OpenAI-compatible" below.

### `model_config` — which models to try, in what order

```json
{
  "models": [
    { "provider": "unorouter", "model": "deepseek-v4.1-flash:free", "enabled": true, "priority": 1, "tier": "free" },
    { "provider": "unorouter", "model": "qwen3.5-122b-a10b:free",   "enabled": true, "priority": 2, "tier": "free" },
    { "provider": "xkiro",     "model": "xkiro-mini:free",          "enabled": true, "priority": 3, "tier": "free" }
  ]
}
```

- `provider` — must match a `name` in `provider_config`.
- `model` — the model id to send that provider.
- `enabled` — set `false` to pause one model without removing it.
- `priority` — lower runs first. Ties keep array order.
- `tier` — `"free"` or `"paid"`. Omit for `"free"`. See the policy below.

### `policy` — the free/paid switch

```json
{ "allow_paid": false }
```

When `allow_paid` is `false` (the default — including when this key is
unset, or KV is unreadable), the pool skips every model marked
`"tier": "paid"` entirely, so a misconfigured or compromised `model_config`
can never accidentally rack up paid usage. Set `true` only when you
deliberately want paid models available, and mark those specific models
`"tier": "paid"` in `model_config` so free-only stays the default everywhere
else.

### Example: adding a hypothetical future free provider

Say "FreeAI Cloud" ships an OpenAI-compatible `/v1/chat/completions` API.
No code change, no Flutter change, no deploy:

```bash
wrangler secret put FREEAI_API_KEY
```

Then update `provider_config` to add:

```json
{ "name": "freeai", "baseUrl": "https://api.freeaicloud.example", "secretName": "FREEAI_API_KEY", "enabled": true }
```

and add its model(s) to `model_config`:

```json
{ "provider": "freeai", "model": "freeai-large:free", "enabled": true, "priority": 4, "tier": "free" }
```

That's it — the next request to `unorouter`/`auto` can pick it up.

### Adding a provider that isn't fully OpenAI-compatible

If a provider's request/response shape differs from plain OpenAI (different
auth header, different body wrapper, etc.), it needs one small addition in
`worker.js`: an entry in the `PROVIDER_ADAPTERS` map with a `buildRequest()`
for that wire format, referenced by name via `"adapter"` in that provider's
`provider_config` entry. This is the *only* code most future providers should
ever need — the routing/fallback loop, the KV schema, and the Flutter app
are untouched either way.

### Writing the KV values

```bash
wrangler kv key put --binding=MODEL_CONFIG_KV "provider_config" --path provider_config.json
wrangler kv key put --binding=MODEL_CONFIG_KV "model_config" --path model_config.json
wrangler kv key put --binding=MODEL_CONFIG_KV "policy" '{"allow_paid": false}'
```

(or paste the same JSON into **Workers & Pages → your Worker → KV** in the
dashboard). No `wrangler deploy` is needed for KV-only changes.

### Replacing all existing free models with new ones

Write a new `model_config` value containing only the new `{provider, model}`
entries (and, if they're on a provider not yet listed, add that provider to
`provider_config` too). The next request picks up the new list immediately —
existing installs of the app keep working unchanged, because they never see
model ids at all; they only ever talk to this Worker's fixed endpoint.

### Safe fallback if KV is unavailable

If `MODEL_CONFIG_KV` is unbound, a key is unreadable, or a value is missing
or invalid JSON, the Worker falls back to a small hard-coded default
(`DEFAULT_PROVIDER_CONFIG` + `DEFAULT_MODEL_CONFIG` in `worker.js` —
UnoRouter with the same free models this pool shipped with originally) so
the Assistant keeps working. The old `model_pool` KV key (the UnoRouter-only
model list from before this pool supported multiple providers) is also
still read as a secondary fallback if `model_config` hasn't been written
yet, so nothing already deployed to KV is lost.

### Bounded fallback

The pool tries at most `MAX_POOL_ATTEMPTS` (20) `{provider, model}`
candidates per request and gives each one a 25s timeout
(`MODEL_ATTEMPT_TIMEOUT_MS`) before moving on — a huge or slow
`model_config`, or several down providers in a row, can't turn into an
unbounded retry loop.

### Confirming the Flutter APK doesn't need to be rebuilt

None of the above changes the Worker's public contract: still
`POST /v1/chat/completions`, still the same request/response shape, still
selected the same way (`X-AI-Provider` header, `provider` body field, or
`DEFAULT_PROVIDER`). Adding, removing, or reordering providers/models, or
flipping `allow_paid`, is entirely a KV write — the Flutter app, already
built and in users' hands, keeps working without any update, rebuild, or
Play Store release.


## Current Affairs RSS cache

The Worker also exposes `GET /api/current-affairs/latest`. It fetches metadata only from the configured public RSS feeds, removes duplicate stories by canonical article URL/title, and returns separate `national` and `international` arrays. Each story contains its title, source, category, publication time, excerpt, optional image URL, and original article URL. Full article bodies are never stored.

The scheduled Worker trigger refreshes the cache every 15 minutes. The currently configured sources are Express Tribune Pakistan and The News News under `National`, and BBC World, Express Tribune World, The News World, and Al Jazeera under `International`. A source that temporarily fails contributes no new items while the remaining sources continue to populate the cache.

The Flutter release build can connect the existing Home card by passing:

```bash
flutter build apk --release \
  --dart-define=SAPIORA_CURRENT_AFFAIRS_BASE_URL=https://YOUR_WORKER_URL
```

If the define is omitted or the endpoint is unavailable, the Home card keeps using its bundled mock update. The GitHub Actions release workflow reuses the existing `SAPIORA_AI_BASE_URL` secret for this optional define.

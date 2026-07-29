# Sapiora AI gateway (Cloudflare Worker)

Routes the app's AI Assistant requests to **Forge AI** or **HCNSEC**, or lets
the Worker pick automatically with fallback. The app only ever talks to this
Worker — it never sees, sends, or stores either provider's real API key.

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
| `SAPIORA_AI_PROVIDER` *(optional)* | `auto` (default), `forge`, or `hcnsec` — normally leave unset |

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

Try forcing a specific provider with `-H "X-AI-Provider: forge"` or
`-H "X-AI-Provider: hcnsec"` to test each one individually.

## Testing checklist

- [ ] `auto` with both provider keys set → succeeds via the default provider
- [ ] `auto` with the default provider's key deliberately wrong → automatically
      falls back to the other provider and still succeeds
- [ ] Explicit `X-AI-Provider: forge` → only calls Forge (fails if its key is wrong,
      does *not* silently fall back to HCNSEC)
- [ ] Explicit `X-AI-Provider: hcnsec` → only calls HCNSEC
- [ ] Missing/invalid `Authorization` header → `401` from the Worker itself,
      before either provider is ever called
- [ ] Streaming works end-to-end in the app (tokens appear incrementally, not
      all at once at the end)
- [ ] Stopping generation mid-reply in the app still works (client-side
      cancellation — unchanged, the Worker doesn't need to know)
- [ ] Both providers down/misconfigured → app shows a normal error, not a crash

## Adding another provider later (e.g. Gemini, Claude, Groq, OpenRouter, ...)

1. In `worker.js`, add an entry to the `PROVIDERS` map with its base-URL env
   var name and API-key env var name.
2. `wrangler secret put <NEWPROVIDER>_API_KEY`.
3. Optionally set `<NEWPROVIDER>_BASE_URL` if it's not OpenAI-compatible at
   the default path.
4. Deploy: `wrangler deploy`.

Nothing in the Flutter app changes — it already just sends `X-AI-Provider`
as a hint and lets the Worker do the rest.

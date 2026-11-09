# DarsNexa Current Affairs AI Summaries

Architecture:
- Existing GNews + RSS Worker remains the source of article metadata.
- This Worker indexes article metadata in KV.
- Cron generates at most 20 new exam-relevant summaries per UTC day.
- Other articles are summarized only after the first user taps AI Summary.
- Every generated summary is cached for 30 days and reused by all users.
- The AI call goes through the existing DarsNexa AI gateway.

Deploy:
1. Create KV: wrangler kv namespace create CURRENT_AFFAIRS_KV
2. Put the returned ID into wrangler-current-affairs-ai.toml.
3. Set AI_KEY to the same value as the existing Worker's WORKER_SHARED_KEY.
4. wrangler deploy --config wrangler-current-affairs-ai.toml
5. Set the Flutter define SAPIORA_CURRENT_AFFAIRS_SUMMARY_BASE_URL to this Worker's URL.

Endpoint:
GET /api/current-affairs/summary?id=<article-id>

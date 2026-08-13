# Current Affairs RSS findings

The existing backend surface is `cloudflare-worker/worker.js`, currently an AI gateway with no KV/D1/R2 binding or cron trigger in `wrangler.toml`. The Flutter app is offline-first and currently has no news API client or remote news cache.

Verified source pages:

- Express Tribune RSS directory: `https://tribune.com.pk/rss`
  - Active feeds include `https://tribune.com.pk/feed/pakistan`, `https://tribune.com.pk/feed/latest`, and `https://tribune.com.pk/feed/world`.
  - The directory states that feeds provide headlines, summaries, and content updated throughout the day.
- The News International RSS directory: `https://www.thenews.com.pk/rss`
  - National/news feed: `https://www.thenews.com.pk/rss/1/0`.
  - World feed: `https://www.thenews.com.pk/rss/1/2`.
  - The directory exposes feed title, link, and a generic RSS image; item-level metadata must be tested from the feed XML.

The planned backend should classify Express Tribune Pakistan and The News News as National, and Express Tribune World and The News World as International. BBC World and Al Jazeera should be validated next before adding their feed URLs. Metadata-only storage should include title, source, category, publication time, excerpt, image URL when present, and original article URL; no article body should be stored.

The official BBC pages were policy-blocked in the sandbox browser, so the current BBC candidate remains `https://feeds.bbci.co.uk/news/world/rss.xml`, which is widely documented but should be health-checked by the backend at runtime. The official Al Jazeera site also needs runtime feed validation; use it only when its feed returns valid RSS/Atom items, as requested.

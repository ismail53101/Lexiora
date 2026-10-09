# DarsNexa mandatory update policy

The app reads `docs/app_update.json` on startup. The policy is hosted as a public raw GitHub file, so the minimum supported build can be changed without another app release.

## Requiring a newer build

1. Release the new AAB to Google Play with a higher `versionCode` (the number after `+` in `pubspec.yaml`).
2. After that release is available to users, edit `minimumVersionCode` in `docs/app_update.json` to the minimum build you want to allow.
3. Commit the JSON change. App builds that already contain the update-check code will show a non-dismissible dialog when their installed build number is below the configured minimum.
4. Keep `storeUrl` pointed at the existing Play Store listing. The app ID is currently `com.sapiora.app`, even though the public brand is DarsNexa.

## Important limitation

An already-installed older build cannot gain code it never shipped with. Therefore, the first DarsNexa release containing this checker cannot display this custom dialog inside older Sapiora builds that lack it. Those users must first receive/install that release through Google Play. From then on, the remote minimum can enforce future mandatory updates on versions containing this checker.

The check fails open if the remote policy cannot be reached, to avoid locking users out during a network or GitHub outage.

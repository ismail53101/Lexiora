# Release signing (required for the Play Store)

Play Store rejects debug-signed uploads. This generates your own **upload
keystore** once, then wires it in so every future release build (local or
via GitHub Actions) is signed with it automatically.

⚠️ **Back this file up somewhere safe (password manager, encrypted drive).**
If you lose it, you can't publish updates to the same Play Store listing —
Google would treat any new upload as an unrelated app.

## 1. Generate the keystore (once, on your own computer)

Requires a JDK (comes with Android Studio). Run:

```bash
keytool -genkey -v -keystore sapiora-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

It'll ask for:
- A **keystore password** (remember this)
- Your name/org details (anything reasonable — not user-facing)
- A **key password** (can be the same as the keystore password)

This creates `sapiora-upload-key.jks`. **Keep it private — never commit it.**

## 2. Local builds (optional — only needed if you build release APK/AAB
   yourself, not via GitHub Actions)

Create `android/key.properties` (already git-ignored):

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=upload
storeFile=/absolute/path/to/sapiora-upload-key.jks
```

That's it — `android/app/build.gradle.kts` picks this up automatically and
release builds will be signed with it instead of the debug key.

## 3. GitHub Actions (recommended — so CI builds are Play-Store-ready)

The keystore file itself needs to reach the CI runner without ever being
committed. Standard approach: base64-encode it into a GitHub secret, decode
it back to a file at build time.

**On your computer:**

```bash
# macOS/Linux:
base64 -i sapiora-upload-key.jks | tr -d '\n' > keystore_base64.txt
# Windows (PowerShell):
[Convert]::ToBase64String([IO.File]::ReadAllBytes("sapiora-upload-key.jks")) | Out-File keystore_base64.txt -NoNewline
```

**In GitHub → Settings → Secrets and variables → Actions**, add:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | contents of `keystore_base64.txt` |
| `ANDROID_KEYSTORE_PASSWORD` | your keystore password |
| `ANDROID_KEY_PASSWORD` | your key password |
| `ANDROID_KEY_ALIAS` | `upload` (or whatever alias you used) |

Then delete `keystore_base64.txt` locally — it's served its purpose.

The workflow step that decodes these into `android/key.properties` before
building is already wired in `.github/workflows/build.yml` — once the four
secrets above exist, every build automatically becomes properly signed; no
further code changes needed.

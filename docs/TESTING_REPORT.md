# Lexiora — Phase 1.1 Testing Report

Date: 2026-07-24 · Version: **0.1.5+6**

## What changed since 0.1.4

Discovery is now **fully automatic and reference-in-place**: on opening the
Library (and on pull-to-refresh) Lexiora walks the device's shared storage and
lists every PDF, opening each file at its real path. There is no Import button
and no "Find on device" menu. On Android 11+ this uses one-time **All files
access** (`MANAGE_EXTERNAL_STORAGE`); on Android ≤ 10 it uses the legacy read
permission. The earlier reader and permission fixes (below) are retained.

## Root cause of the release-only reader failure (fixed in 0.1.2, still in place)

The reader failed to open **every** PDF in the **release** APK (blank in 0.1.0,
then the diagnostic error screen in 0.1.1), while the rest of the app worked.

- **Diagnosis (from APK evidence):** `unzip -v` showed `lib/arm64-v8a/libpdfium.so`
  was **`Stored`** — uncompressed and **not extracted** — because release APKs
  default to `extractNativeLibs=false`.
- **Why it broke:** pdfrx loads PDFium with `DynamicLibrary.open('libpdfium.so')`
  (bare name). Android's FFI `dlopen` can't resolve a bare-named library that is
  packed (unextracted) inside the APK, so the call throws at render time. Debug
  builds extract native libs, which is why only release was affected.
- **Fix:** `packaging { jniLibs { useLegacyPackaging = true } }` in
  `android/app/build.gradle.kts`. The APK now ships `libpdfium.so` **deflated and
  extracted at install** (`extractNativeLibs=true`), so `dlopen` resolves. This
  was confirmed by the user on-device ("previous issue is fine now").

---

## How this was verified

Lexiora is fixed and built in a headless environment (Flutter 3.44.8, Android
SDK, JDK 17) that has **no Android emulator or physical device**. Everything
that can be checked without a running device has been checked here; everything
that requires a live device is listed in the on-device checklist below.

### ✅ Machine-verified in this environment (0.1.5)

| Check | Result |
|---|---|
| `flutter analyze` (strict, all lints) | **0 issues** |
| `flutter test` (unit + widget) | **11/11 passing** |
| `dart run build_runner build` (Drift codegen) | **Success (202 outputs)** |
| Native Kotlin compilation (channel: SDK int, keep-awake, all-files check, `scanAllPdfs` FS walk) | **Passes** |
| **Release** APK build (`flutter build apk --release --target-platform android-arm64`) | **Success — app-release.apk ≈ 12.9 MB** |
| Native packaging (`unzip -v`) | `libpdfium.so` / `libsqlite3.so` present, **`extractNativeLibs` on** |
| APK manifest permissions | `MANAGE_EXTERNAL_STORAGE` + `READ_EXTERNAL_STORAGE` (maxSdk 29) present |

Automated tests include a widget test asserting the reader's error state renders
an explained `ErrorView` with working Retry/Back (the "never blank" guarantee),
plus unit tests for the `Result` type, reading-progress math, bookmark toggle,
settings and library models.

### 📱 On-device checks to confirm (require a phone/emulator)

Verify on real hardware in **both Debug and Release**. Watch logs with
`flutter logs` / `adb logcat` — Lexiora logs discovery and every reader step
under the tag `Lexiora`.

**Critical bug 1 — Reader**
- [ ] Open several PDFs (small, large 500+ pages, scanned) — each opens and renders.
- [ ] No blank screen ever: on a deliberately corrupted/renamed file, the reader shows the error page with Retry/Back (not blank).
- [ ] Last page is remembered; auto-resume on/off behaves correctly.

**Critical bug 2 — Permissions**
- [ ] Android 11+: first open of the Library requests **All files access**; granting it returns straight to a populated library.
- [ ] Deny → the Library shows the "Allow access to your files" state with Grant + Open settings (never a blank screen or a crash).
- [ ] Android ≤ 10: the system storage-permission dialog appears instead.

**Critical bug 3 — Automatic discovery**
- [ ] With access granted, the Library auto-populates with PDFs from Downloads / Documents / anywhere on the device, with **no button press**.
- [ ] Pull-to-refresh (and the AppBar refresh) picks up newly added files and reports "Added N new PDFs" / "Library is up to date".
- [ ] Re-scanning adds only new PDFs (dedup by absolute path — no duplicates).
- [ ] "Remove from library" deletes only the entry; the file stays on the device and reappears on the next scan.

**Features**
- [ ] Highlights (yellow/green/blue/pink), underline, edit color, delete — persist across restarts.
- [ ] Notes (add/edit/delete), incl. selection-anchored; bookmarks add/delete/jump.
- [ ] Library search & sort; Settings theme/font/keep-awake/auto-resume.

**CI**
- [ ] Push to GitHub → the Actions workflow goes green and publishes the release APK to the `v0.1.5` release.

## Known constraints
- **All-files access on Android 11+.** Automatic device-wide discovery requires
  `MANAGE_EXTERNAL_STORAGE`. This is a Google Play **sensitive** permission and
  needs a declaration at submission (a document-reader use case qualifies).
  Direct APK / sideload distribution is unaffected. The discovery layer is
  isolated behind `PdfDiscoveryService` + `PermissionService`, so a
  Play-review-friendly SAF folder-grant model can be substituted without
  touching the reader or library UI.
- **GitHub push** must be done with your own credentials — the connected
  integration is read-only (see the delivery notes).

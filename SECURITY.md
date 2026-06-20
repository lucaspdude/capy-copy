# Security model for Capy Copy

Capy Copy is a menu-bar clipboard history manager for macOS 14+. This document describes what the app does with your clipboard, what it does **not** do, and the trust boundaries we maintain. Read this before copying sensitive data while Capy Copy is running.

> **Note about this project**  
> Capy Copy was developed with the assistance of artificial intelligence tools. The security design, implementation, and documentation were produced through a collaborative process between human oversight and AI-assisted generation. If you find a vulnerability, please report it so we can fix it.

## TL;DR

- Clipboard content is stored **locally**, encrypted with a per-device key in the macOS Keychain.
- Capy Copy makes **no network calls** and does not fetch web pages.
- Optional on-device analysis with Apple Intelligence is **disabled by default**. When enabled, no clipboard text leaves the device.
- It does **not** show notifications in version 1.0.0.
- Only device identity and preferences can optionally sync via CloudKit. **Clipboard content is never uploaded.**
- The app is distributed outside the Mac App Store and therefore **does not use the App Sandbox**. This is required so it can paste into other applications using a synthesized Cmd+V keystroke.

## What the app does

1. **Watches the pasteboard.** Capy Copy reads the system pasteboard change count periodically. When it advances, the app reads the text, image, or video URL the system put there.
2. **Filters secrets.** Strings that look like passwords, API tokens, high-entropy base64, or have high Shannon entropy are not persisted.
3. **Persists locally.** Surviving clips are encrypted with ChaChaPoly using a per-device 256-bit key stored in the macOS Keychain, then written to `~/Library/Application Support/capy-copy/history.json` with `0o600` permissions, `.completeFileProtection`, and excluded from Time Machine / iCloud Drive backups. An HMAC-SHA256 tag is written first, derived from the storage key via HKDF-SHA256, so the same key is never used for both cipher and authentication.
4. **Lets you act on clips.** Open the picker and run local actions: paste into another app, open a URL in Maps, add a date to Calendar or Reminders. None of these leave the device.
5. **Syncs a small amount of metadata via iCloud (optional).** `DeviceIdentity` and `SettingsStore` preferences can sync between your Macs via CloudKit private database. Clipboard content is not in CloudKit.

## What the app does not do

- **No cloud AI or large language models.** Capy Copy does not send clipboard text to any cloud service for analysis.
- **No subprocesses for analysis.** Capy Copy does not spawn external tools to process clipboard content.
- **No HTTP / HTTPS.** Capy Copy does not import `URLSession` for fetching remote content.
- **No notifications.** Capy Copy does not import `UserNotifications`. Banner notifications are a possible future feature.
- **No cross-device clipboard content sync.** Only device identity, preferences, and (when AI analysis is enabled on both sides) analysis results cross the CloudKit boundary.
- **No analytics or telemetry.** Nothing in the app phones home.

## Optional on-device analysis

When you enable **Auto-analyze clipboard** in Settings:

- Copied text is analyzed by Apple Intelligence **on your Mac**.
- No clipboard text is sent to the cloud or to any third-party service.
- Analysis is gated by per-category toggles (plain text/dates, URLs, code).
- Analysis results sync via CloudKit only when the receiving Mac also has auto-analyze enabled.
- The feature requires macOS 15+ and Apple Silicon; it is unavailable on older hardware.

## Trust boundaries

### Pasteboard → persistence

`ClipboardFilter.decision(for:)` checks the text against rules for length, character classes, and entropy. Filtered-out text is never persisted, never sent to any model, and never displayed.

### Persistence → disk

`HistoryPersistence` is an `actor` whose public interface is limited to `load()` and `save()`. The on-disk format is:

```
[ 32 bytes HMAC-SHA256 tag ] [ ChaChaPoly.SealedBox.combined ]
```

The HMAC key is `HKDF-SHA256(primaryKey, info: "capy-copy.history.hmac.v1")`. Both the encryption and the HMAC key are derived from a single Keychain-backed 256-bit secret stored with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` and **no** `kSecAttrSynchronizable` flag — the key never leaves the device.

### Persistence → iCloud

CloudKit private database contains `DeviceIdentity` and `SettingsStore` preferences. No raw `ClipItem` row is written to CloudKit. The encryption key does not sync.

If AI analysis is enabled, a small amount of derived metadata (the analysis result) may sync via CloudKit, but only when the receiving Mac also has auto-analyze enabled. Raw clipboard text never crosses the CloudKit boundary.

### Paste → target app

`PasteHelper.triggerPaste` synthesises a Cmd+V keystroke with `CGEvent` and posts it to the `cgSessionEventTap` after activating the user's target app via `NSRunningApplication.activate(options:)`. This requires the user to grant Accessibility to Capy Copy in **System Settings → Privacy & Security → Accessibility**.

We do **not** use `NSAppleScript`. The previous implementation built an AppleScript source by string-interpolating the target app's `bundleIdentifier` into a `tell application id "..."` block. A maliciously-crafted bundle identifier could have broken out of the `tell` block. CGEvent Cmd+V is auditable in one screen of Swift and requires only the Accessibility entitlement, which is why Capy Copy 1.0.0 ships **without** `com.apple.security.automation.apple-events`.

### Sandboxing

Capy Copy is distributed as a Developer ID-signed, notarized DMG outside the Mac App Store. Because synthesizing keystrokes for another app is incompatible with the App Sandbox, both `capy-copy.entitlements` (ad-hoc / dev) and `capy-copy.production.entitlements` (Developer ID) ship **without** `com.apple.security.app-sandbox`.

The production entitlements include:

- `com.apple.developer.icloud-services: [CloudKit]`
- `com.apple.developer.icloud-container-identifiers: [iCloud.dev.capy-copy]`

Excluded by design:

- `com.apple.security.app-sandbox` — required for cross-app paste.
- `com.apple.security.cs.allow-jit` — no JIT runtime in the app.
- `com.apple.security.automation.apple-events` — CGEvent paste is sufficient.
- `com.apple.security.network.client` — 1.0.0 makes no network calls.

## What users should know

- If you copy a password, it will not be persisted, but it **will** be read by Capy Copy the moment you copy it. The filter is best-effort — treat Capy Copy as a "reads the pasteboard" app, like any other clipboard manager.
- If you clear your Keychain, sign out of iCloud, or wipe the device, the encryption key is lost. The history file becomes permanently unrecoverable and the app will start with an empty history.
- If you revoke Accessibility, paste stops working, but reading the clipboard and history still work.
- If you uninstall Capy Copy, the encrypted history file and Keychain key are removed by macOS (the Keychain entry is tied to the app's bundle ID).

## Threat model

### Defended against

- A second user reading the encrypted history file while the first user is logged out.
- A Time Machine / iCloud Drive backup leaking the raw history.
- A pastejack attack that pushes a high-entropy token to the pasteboard to harvest it later: the filter catches 16+ character high-entropy strings.
- A malicious target app with a `bundleIdentifier` crafted to break out of a string-built AppleScript.
- Apple itself reading clipboard content from the encrypted file (the encryption key is local, so the ciphertext is opaque to iCloud).
- An attacker who can write a file to the history path: the HMAC tag is verified before decryption, so garbage is rejected.

### Not defended against

- A user who runs the app while logged in and a user-space attacker has the ability to inspect the running process. The encryption key is in the same process.
- A keylogger that observes the user's keystrokes before the pasteboard.
- A different clipboard manager that captures the data before Capy Copy does. Capy Copy is not the only reader of the pasteboard.
- A device that is already compromised. Capy Copy is a Swift app on stock macOS; it cannot defend against a rooted OS.

## Reporting a vulnerability

Please open a private issue on GitHub or email `lucaspdude@gmail.com` with a description and, if possible, a proof-of-concept. We do not currently run a bug bounty program, but we will acknowledge within 7 days and aim to ship a fix in the next minor release.

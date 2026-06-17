# capy-copy

The macOS menu-bar clipboard assistant. This file is the glossary for the capy-copy domain; keep it tight, opinionated, and free of implementation details.

## Core domain

**Clip**: A single unit of data captured from `NSPasteboard.general`, plus everything derived from it (classification, model result, extracted dates, suggested actions). The smallest unit of history persistence.
_Avoid_: item, entry, record.

**Raw text**: The unprocessed string read from the pasteboard. The clip's source of truth for everything downstream.
_Avoid_: source, input, content (overloaded with "file content", "page content", etc.).

**History**: The persisted, ordered list of clips. Local copy is encrypted at rest with a Keychain-backed ChaChaPoly key. iCloud sync is ciphertext only — the encryption key is never synchronised.
_Avoid_: log, archive, store (overloaded).

**Filter decision**: The classification of a candidate clip as `accept` or `ignore(.empty | .tooShort | .likelySecret)`. A clip that fails the filter is never persisted, never displayed, and never sent to the model.
_Avoid_: gate, check, validator.

**Analysis**: The output of running `fm` (the on-device Foundation Model CLI) on a clip's raw text or on a fetched URL's content. Stored as `result` on the `ClipItem`.
_Avoid_: summary, response, completion.

**Suggested action**: A follow-up the user can take on a classified clip — Add to Calendar, Create Reminder, Open in Maps. Rendered as a button in the Quick Picker.
_Avoid_: action, button, shortcut.

**Quick picker**: The main popover UI; the surface for browsing, searching, and acting on history.
_Avoid_: popover, window, UI.

## Trust boundaries

**Trusted paste target**: The app the user is currently working in. capy-copy posts Cmd+V into it via `CGEvent` on the `cghidEventTap` after the user grants Accessibility. The bundle identifier of the target is never interpolated into a string used for execution.
_Avoid_: frontmost app, target app, destination.

**Sandbox posture**: The fixed entitlement set capy-copy ships with. Current: `com.apple.security.app-sandbox` + `com.apple.security.network.client` + `com.apple.security.files.user-selected.read-write` (+ CloudKit container in the production build). Excluded by intent: `com.apple.security.cs.allow-jit` (no JIT runtime in the app), `com.apple.security.automation.apple-events` (CGEvent paste, not AppleScript).
_Avoid_: permissions, capabilities.

**Release posture**: The collection of properties that define how a build is shipped. capy-copy 1.0.0 is the first public release. The build is Developer-ID-signed, Hardened-Runtime-enabled, Notarized via `notarytool`, and shipped as a DMG. The Mac App Store is on the roadmap but is not the 1.0.0 target.
_Avoid_: packaging, distribution model.

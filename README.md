# 🌿 Capy Copy

Capy Copy is a lightweight clipboard history manager for macOS. It lives in your menu bar, remembers what you copy, and helps you paste it back quickly — whether it is a link, a snippet of code, a date, or an address.

> **Note about this project**  
> Capy Copy was developed with the assistance of artificial intelligence tools. The code, design decisions, and documentation were produced through a collaborative process between human oversight and AI-assisted generation.

## What it does

- **Keeps clipboard history** — text, images, and video links you copy are saved locally so you can find them again.
- **Classifies content automatically** — detects URLs, code snippets, dates, addresses, and plain text.
- **Puts anything back on your clipboard** — open the picker with a global shortcut, pick an item, and press **Enter** to paste.
- **Opens useful actions** — add detected dates to Calendar or Reminders, open addresses in Maps.
- **Encrypts your history** — stored locally with a per-device key in the macOS Keychain.
- **Filters out noise** — ignores short text, likely passwords, and duplicates.
- **Speaks your language** — interface follows your macOS system language when a translation is available.

## What it does not do

- It does not use AI or large language models.
- It does not fetch web pages or summarize URLs.
- It does not send clipboard content to the cloud.
- It does not show notifications in version 1.0.0.
- It does not make network calls.

## Requirements

- macOS 14 (Sonoma) or later
- Swift 5.9+

## Build from source

```bash
swift build -c release
```

## Package as an app bundle

```bash
./scripts/package-app.sh v0.1.0
```

This creates `capy-copy.app` and a signed, notarized `capy-copy-0.1.0.dmg` if your signing credentials are configured. See `CONTRIBUTING.md` for the required environment variables.

## Download & install

Pre-built, notarized releases are published on [GitHub Releases](../../releases). Download the latest `.dmg`, open it, and drag **Capy Copy** into your **Applications** folder.

## Releases

Releases are managed by [release-please](https://github.com/googleapis/release-please). When changes are merged into `main`, release-please opens a release pull request with a changelog. Merging that pull request creates a GitHub Release and tag, which then triggers a workflow that builds and attaches the signed DMG.

## Usage

1. Launch Capy Copy — it appears as a capybara icon in your menu bar.
2. Copy text, a URL, code, a date, or an address to your clipboard.
3. Click the menu bar icon **or press ⌘⇧V** to open the picker.
4. Search or browse your history, then press **Enter** to paste the selected item into the app you were using.
5. For dates and addresses, press the action button to add to Calendar/Reminders or open in Maps.
6. Click ⚙️ for Settings, 🗑 to clear history, or ⏻ to quit.

> **Accessibility permission**  
> The first time you paste with Enter, macOS asks you to grant Capy Copy accessibility access. This is required so the app can switch focus back to your target app and send a Cmd+V keystroke. The app does not read screen contents or interact with other apps in any other way.

## Localization

Capy Copy supports the following locales:

- English (`en`)
- Portuguese (Brazil) (`pt-BR`)
- Spanish (`es`)
- German (`de`)
- French (`fr`)
- Japanese (`ja`)
- Simplified Chinese (`zh-Hans`)

Translations fall back to English when a key is missing. To add a new locale:

1. Create `Sources/capy-copy/Resources/<locale>.lproj/Localizable.strings`.
2. Copy the keys from `en.lproj/Localizable.strings` and translate the values.
3. Add the locale to `Tests/capy-copyTests/LocalizationTests.swift`.

## Architecture

```
capy-copy/
├── Sources/capy-copy/
│   ├── App/              # App lifecycle and dependency assembly
│   ├── MenuBar/          # NSStatusItem, global hotkey, picker window
│   ├── Clipboard/        # NSPasteboard monitoring and filtering
│   ├── Analysis/         # Rule-based content classification
│   ├── History/          # Encrypted persistence and deduplication
│   ├── Settings/         # User preferences
│   ├── Sync/             # CloudKit metadata sync (settings, not clipboard content)
│   ├── System/           # Calendar, maps, paste helpers
│   ├── UI/               # SwiftUI views and theme
│   └── Resources/        # Localizations and app icon
└── Tests/capy-copyTests/ # Unit and localization tests
```

## Testing

```bash
swift test
```

## Security

See [`SECURITY.md`](SECURITY.md) for details on how clipboard data is handled, what stays local, and what permissions the app requires.

## License

MIT

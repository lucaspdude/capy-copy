#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load local environment overrides (e.g. signing credentials) from .env.local
ENV_LOCAL="$PROJECT_DIR/.env.local"
if [ -f "$ENV_LOCAL" ]; then
  set -a
  # shellcheck source=/dev/null
  . "$ENV_LOCAL"
  set +a
fi

APP_NAME="${APP_NAME:-capy-copy.app}"
BUNDLE_ID="${BUNDLE_ID:-dev.capy-copy}"
DEVELOPER_ID="${DEVELOPER_ID:-}"

cd "$PROJECT_DIR"

# Version handling
TAG="${1:-v1.0.0}"
if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: Tag must match vMAJOR.MINOR.PATCH (e.g., v1.2.3). Got: $TAG" >&2
  exit 1
fi
VERSION="${TAG#v}"
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
BUNDLE_VERSION=$((MAJOR * 10000 + MINOR * 100 + PATCH))
DMG_NAME="capy-copy-${VERSION}.dmg"

echo "Building release binary for $TAG (bundle version $BUNDLE_VERSION)..."
swift build -c release

# SwiftPM's generated resource bundle accessor looks for the bundle at the app
# bundle root, which codesign rejects as "unsealed contents". Patch it to look
# in the standard Contents/Resources/ location and rebuild.
ACCESSOR_FILE=$(find .build -path "*capy_copy.build/DerivedSources/resource_bundle_accessor.swift" -print -quit)
if [ -n "$ACCESSOR_FILE" ]; then
    sed -i '' 's|Bundle.main.bundleURL.appendingPathComponent("capy-copy_capy-copy.bundle")|Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/capy-copy_capy-copy.bundle")|g' "$ACCESSOR_FILE"
    swift build -c release
fi

echo "Packaging $APP_NAME..."
rm -rf "$APP_NAME" "${DMG_NAME}"
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"

cp ".build/release/capy-copy" "$APP_NAME/Contents/MacOS/"
cp -R ".build/release/capy-copy_capy-copy.bundle" "$APP_NAME/Contents/Resources/"

cat > "$APP_NAME/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Capy Copy</string>
    <key>CFBundleExecutable</key>
    <string>capy-copy</string>
    <key>CFBundleIconFile</key>
    <string>capy_icon</string>
    <key>CFBundleIconName</key>
    <string>capy_icon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Capy Copy</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUNDLE_VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© 2026 Capy Copy. All rights reserved.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>Capy Copy uses Accessibility to paste text into the app you are working in.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Capy Copy needs to open Maps and Calendar for detected addresses and dates.</string>
    <key>NSCalendarsUsageDescription</key>
    <string>Capy Copy can create calendar events from copied dates.</string>
    <key>NSRemindersUsageDescription</key>
    <string>Capy Copy can create reminders from copied dates.</string>
</dict>
</plist>
EOF

if [ -n "${PROVISIONING_PROFILE_PATH:-}" ]; then
    echo "Embedding provisioning profile..."
    cp "$PROVISIONING_PROFILE_PATH" "$APP_NAME/Contents/embedded.provisionprofile"
fi

if [ -f "Sources/capy-copy/Resources/capy_icon.png" ]; then
    ICONSET="$APP_NAME/Contents/Resources/capy-copy_capy-copy.bundle/capy_icon.iconset"
    mkdir -p "$ICONSET"
    sips -z 16 16 "Sources/capy-copy/Resources/capy_icon.png" --out "$ICONSET/icon_16x16.png" >/dev/null
    sips -z 32 32 "Sources/capy-copy/Resources/capy_icon.png" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
    sips -z 32 32 "Sources/capy-copy/Resources/capy_icon.png" --out "$ICONSET/icon_32x32.png" >/dev/null
    sips -z 64 64 "Sources/capy-copy/Resources/capy_icon.png" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
    sips -z 128 128 "Sources/capy-copy/Resources/capy_icon.png" --out "$ICONSET/icon_128x128.png" >/dev/null
    sips -z 256 256 "Sources/capy-copy/Resources/capy_icon.png" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
    sips -z 256 256 "Sources/capy-copy/Resources/capy_icon.png" --out "$ICONSET/icon_256x256.png" >/dev/null
    sips -z 512 512 "Sources/capy-copy/Resources/capy_icon.png" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
    sips -z 512 512 "Sources/capy-copy/Resources/capy_icon.png" --out "$ICONSET/icon_512x512.png" >/dev/null
    sips -z 1024 1024 "Sources/capy-copy/Resources/capy_icon.png" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
    iconutil -c icns "$ICONSET" -o "$APP_NAME/Contents/Resources/capy-copy_capy-copy.bundle/capy_icon.icns"
    cp "$APP_NAME/Contents/Resources/capy-copy_capy-copy.bundle/capy_icon.icns" "$APP_NAME/Contents/Resources/capy_icon.icns"
    rm -rf "$ICONSET"
fi

chmod +x "$APP_NAME/Contents/MacOS/capy-copy"

ENTITLEMENTS_FILE="capy-copy.entitlements"
if [ -n "$DEVELOPER_ID" ] && [ "$DEVELOPER_ID" != "-" ] && [ -f "capy-copy.production.entitlements" ]; then
    ENTITLEMENTS_FILE="capy-copy.production.entitlements"
fi

if [ -n "$DEVELOPER_ID" ]; then
    echo "Signing $APP_NAME with $DEVELOPER_ID..."
    codesign --sign "$DEVELOPER_ID" \
        --force --deep --options runtime \
        --entitlements "$ENTITLEMENTS_FILE" \
        "$APP_NAME"
else
    echo "DEVELOPER_ID not set; applying ad-hoc signature so Accessibility permission can persist..."
    codesign --sign - \
        --force --deep \
        --entitlements capy-copy.entitlements \
        "$APP_NAME"
fi

echo "Building $DMG_NAME..."
if command -v create-dmg >/dev/null 2>&1; then
    create-dmg \
      --volname "Capy Copy Installer" \
      --window-size 600 400 \
      --icon-size 100 \
      --app-drop-link 450 185 \
      --icon "capy-copy.app" 150 185 \
      "${DMG_NAME}" \
      "$APP_NAME"
else
    echo "WARNING: create-dmg not found; falling back to hdiutil"
    STAGING_DIR="$(mktemp -d)"
    cp -R "$APP_NAME" "$STAGING_DIR/"
    ln -s /Applications "$STAGING_DIR/Applications"
    hdiutil create -srcfolder "$STAGING_DIR" -volname "Capy Copy Installer" -format UDZO -ov "${DMG_NAME}"
    rm -rf "$STAGING_DIR"
fi

if [ -n "$DEVELOPER_ID" ] && [ "$DEVELOPER_ID" != "-" ]; then
    echo "Signing $DMG_NAME..."
    codesign --sign "$DEVELOPER_ID" --force "${DMG_NAME}"
fi

echo "Done: $PROJECT_DIR/$APP_NAME"
echo "Installer: $PROJECT_DIR/$DMG_NAME"

APPLE_ID="${APPLE_ID:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
APPLE_APP_SPECIFIC_PASSWORD="${APPLE_APP_SPECIFIC_PASSWORD:-}"

if [ -n "$APPLE_ID" ] && [ -n "$APPLE_TEAM_ID" ] && [ -n "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    echo "Notarizing $DMG_NAME..."
    if [ -n "${NOTARYTOOL_PROFILE:-}" ]; then
        # Credentials are stored in a keychain profile (set up via
        # `xcrun notarytool store-credentials`). Never put the password in argv.
        xcrun notarytool submit "${DMG_NAME}" \
            --keychain-profile "$NOTARYTOOL_PROFILE" \
            --wait
    else
        xcrun notarytool submit "${DMG_NAME}" \
            --team-id "$APPLE_TEAM_ID" \
            --apple-id "$APPLE_ID" \
            --password "$APPLE_APP_SPECIFIC_PASSWORD" \
            --wait
    fi
    # Staple the notarization ticket. Some Xcode versions removed the
    # `notarytool staple` subcommand; fall back to `stapler` when needed.
    if xcrun notarytool --help 2>/dev/null | grep -q '\bstaple\b'; then
        xcrun notarytool staple "${DMG_NAME}"
    else
        xcrun stapler staple "${DMG_NAME}"
    fi
    echo "Notarization complete."
else
    echo "WARNING: Apple ID credentials not set; skipping notarization"
fi


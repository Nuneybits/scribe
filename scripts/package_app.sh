#!/bin/zsh

set -euo pipefail

CONFIGURATION="${1:-release}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Scribe"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
MODULE_CACHE_DIR="${TMPDIR:-/tmp}/scribe-clang-module-cache"
ICON_SOURCE_FILE="$ROOT_DIR/assets/icons/Scribe.icns"
ICONSET_DIR="$ROOT_DIR/assets/icons/Scribe.iconset"
ICON_FILE="$APP_DIR/Contents/Resources/$APP_NAME.icns"

mkdir -p "$MODULE_CACHE_DIR"

export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR"

(
    cd "$ROOT_DIR"
    swift build --disable-sandbox -c "$CONFIGURATION"
)

BIN_DIR="$(cd "$ROOT_DIR" && swift build --disable-sandbox -c "$CONFIGURATION" --show-bin-path)"

mkdir -p "$DIST_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"

if [[ -f "$ICON_SOURCE_FILE" ]]; then
    cp "$ICON_SOURCE_FILE" "$ICON_FILE"
elif [[ -d "$ICONSET_DIR" ]]; then
    "$ROOT_DIR/scripts/build_icns.sh" "$ICONSET_DIR" "$ICON_FILE"
fi

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Scribe</string>
    <key>CFBundleIdentifier</key>
    <string>com.nuneybits.scribe</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIconFile</key>
    <string>Scribe</string>
    <key>CFBundleName</key>
    <string>Scribe</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.1</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Scribe uses speech recognition to transcribe your local audio files into text.</string>
</dict>
</plist>
PLIST

echo "Packaged $APP_DIR"

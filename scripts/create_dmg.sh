#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Scribe"
DIST_DIR="$ROOT_DIR/dist"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
TEMP_DMG_PATH="$DIST_DIR/$APP_NAME-temp.dmg"
STAGING_DIR="$DIST_DIR/dmg-staging"
ICON_SOURCE_FILE="$ROOT_DIR/assets/icons/Scribe.icns"
ICONSET_DIR="$ROOT_DIR/assets/icons/Scribe.iconset"
VOLUME_ICON_PATH="$STAGING_DIR/.VolumeIcon.icns"

"$ROOT_DIR/scripts/package_app.sh" release

rm -f "$DMG_PATH"
rm -f "$TEMP_DMG_PATH"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

cp -R "$DIST_DIR/$APP_NAME.app" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

if [[ -f "$ICON_SOURCE_FILE" ]]; then
  cp "$ICON_SOURCE_FILE" "$VOLUME_ICON_PATH"
elif [[ -d "$ICONSET_DIR" ]]; then
  "$ROOT_DIR/scripts/build_icns.sh" "$ICONSET_DIR" "$VOLUME_ICON_PATH"
fi

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDRW \
  "$TEMP_DMG_PATH"

if [[ -f "$VOLUME_ICON_PATH" ]]; then
  ATTACH_OUTPUT="$(hdiutil attach "$TEMP_DMG_PATH" -mountpoint "/Volumes/$APP_NAME" -nobrowse)"
  cp "$VOLUME_ICON_PATH" "/Volumes/$APP_NAME/.VolumeIcon.icns"
  SetFile -a C "/Volumes/$APP_NAME"
  SetFile -a V "/Volumes/$APP_NAME/.VolumeIcon.icns"
  hdiutil detach "/Volumes/$APP_NAME" || hdiutil detach -force "/Volumes/$APP_NAME"
fi

if ! hdiutil convert "$TEMP_DMG_PATH" -format UDZO -o "$DMG_PATH"; then
  sleep 2
  hdiutil convert "$TEMP_DMG_PATH" -format UDZO -o "$DMG_PATH"
fi

rm -f "$TEMP_DMG_PATH"
rm -rf "$STAGING_DIR"

echo "Created $DMG_PATH"

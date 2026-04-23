#!/bin/zsh

set -euo pipefail

ICONSET_DIR="${1:?iconset directory required}"
OUTPUT_PATH="${2:?output path required}"

if command -v iconutil >/dev/null 2>&1; then
  if iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_PATH" >/dev/null 2>&1; then
    exit 0
  fi
fi

TEMP_BASE="$(mktemp "${TMPDIR:-/tmp}/scribe-icon.XXXXXX")"
TEMP_TIFF="$TEMP_BASE.tiff"
trap 'rm -f "$TEMP_TIFF"' EXIT

tiffutil -cat \
  "$ICONSET_DIR/icon_16x16.png" \
  "$ICONSET_DIR/icon_16x16@2x.png" \
  "$ICONSET_DIR/icon_32x32.png" \
  "$ICONSET_DIR/icon_32x32@2x.png" \
  "$ICONSET_DIR/icon_128x128.png" \
  "$ICONSET_DIR/icon_128x128@2x.png" \
  "$ICONSET_DIR/icon_256x256.png" \
  "$ICONSET_DIR/icon_256x256@2x.png" \
  "$ICONSET_DIR/icon_512x512.png" \
  "$ICONSET_DIR/icon_512x512@2x.png" \
  -out "$TEMP_TIFF" >/dev/null

tiff2icns "$TEMP_TIFF" "$OUTPUT_PATH"

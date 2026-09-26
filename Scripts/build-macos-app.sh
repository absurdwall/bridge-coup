#!/bin/zsh
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_ROOT"

"$APP_ROOT/Scripts/build-dds-helper.sh"
swift build --configuration release

APP_BUNDLE="$APP_ROOT/.build/macos/Bridge Coup.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
mkdir -p "$CONTENTS_DIR/Helpers"
cp "$APP_ROOT/.build/release/BridgeTeacherMac" "$MACOS_DIR/BridgeTeacherMac"
cp "$APP_ROOT/.build/dds/bridge-dds" "$CONTENTS_DIR/Helpers/bridge-dds"
cp "$APP_ROOT/.build/dds-source-v3.0.0/LICENSE" "$RESOURCES_DIR/DDS-LICENSE.txt"
LOGO_PNG="$APP_ROOT/AppResources/BridgeCoupLogo.png"
WORDMARK_PNG="$APP_ROOT/AppResources/BridgeCoupWordmark.png"
cp "$LOGO_PNG" "$RESOURCES_DIR/BridgeCoupLogo.png"
cp "$WORDMARK_PNG" "$RESOURCES_DIR/BridgeCoupWordmark.png"
chmod 755 "$MACOS_DIR/BridgeTeacherMac"
chmod 755 "$CONTENTS_DIR/Helpers/bridge-dds"

# Build the standard macOS icon sizes directly from the approved square artwork.
# Resizing changes only the pixel dimensions; it does not recolor or recompose it.
ICONSET_DIR="$APP_ROOT/.build/macos/BridgeCoup.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
for SIZE in 16 32 128 256 512; do
	RETINA_SIZE=$((SIZE * 2))
	sips -z "$SIZE" "$SIZE" "$LOGO_PNG" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}.png" >/dev/null
	sips -z "$RETINA_SIZE" "$RETINA_SIZE" "$LOGO_PNG" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/BridgeCoup.icns"
rm -rf "$ICONSET_DIR"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>zh_CN</string>
	<key>CFBundleExecutable</key>
	<string>BridgeTeacherMac</string>
	<key>CFBundleIdentifier</key>
	<string>app.tortillaflat.bridge-teacher</string>
	<key>CFBundleDisplayName</key>
	<string>Bridge Coup</string>
	<key>CFBundleIconFile</key>
	<string>BridgeCoup.icns</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Bridge Coup</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>0.1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_BUNDLE"
printf 'Built %s\n' "$APP_BUNDLE"

#!/bin/zsh
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_ROOT"
source "$APP_ROOT/Scripts/release-identity.sh"

if [[ "$(uname -m)" != arm64 ]]; then
  print -u2 "Release packages require an Apple Silicon build host."
  exit 1
fi
"$APP_ROOT/Scripts/build-dds-helper.sh"
CODEX_RUNTIME="$("$APP_ROOT/Scripts/fetch-codex-runtime.sh")"
swift build --configuration release --arch arm64

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
cp "$APP_ROOT/ThirdPartyNotices/Codex-LICENSE.txt" "$RESOURCES_DIR/Codex-LICENSE.txt"
cp "$APP_ROOT/ThirdPartyNotices/Codex-NOTICE.txt" "$RESOURCES_DIR/Codex-NOTICE.txt"
install -m 755 "$CODEX_RUNTIME" "$RESOURCES_DIR/codex"
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

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
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
	<string>$RELEASE_VERSION</string>
	<key>CFBundleVersion</key>
	<string>$RELEASE_BUILD</string>
	<key>BridgeCoupReleaseTag</key>
	<string>$RELEASE_TAG</string>
	<key>BridgeCoupReleaseLabel</key>
	<string>$RELEASE_LABEL</string>
	<key>BridgeCoupReleaseChannel</key>
	<string>$RELEASE_CHANNEL</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST

# Sign each shipped executable after all files are in place, including any
# future app-owned runtime in Resources, then seal the outer app bundle.
while IFS= read -r -d '' FILE; do
  [[ -x "$FILE" ]] || continue
  [[ "$FILE" == "$MACOS_DIR/BridgeTeacherMac" ]] && continue
  file -b "$FILE" | grep -q 'Mach-O' || {
    print -u2 "Unexpected non-Mach-O executable in app bundle: $FILE"; exit 1
  }
  codesign --force --sign - "$FILE"
done < <(find "$CONTENTS_DIR" -type f -print0)
codesign --force --sign - "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
printf 'Built %s\n' "$APP_BUNDLE"

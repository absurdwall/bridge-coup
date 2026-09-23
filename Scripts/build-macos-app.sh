#!/bin/zsh
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_ROOT"

"$APP_ROOT/Scripts/build-dds-helper.sh"
swift build --configuration release

APP_BUNDLE="$APP_ROOT/.build/macos/BridgeTeacher.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
mkdir -p "$CONTENTS_DIR/Helpers"
cp "$APP_ROOT/.build/release/BridgeTeacherMac" "$MACOS_DIR/BridgeTeacherMac"
cp "$APP_ROOT/.build/dds/bridge-dds" "$CONTENTS_DIR/Helpers/bridge-dds"
cp "$APP_ROOT/.build/dds-source-v3.0.0/LICENSE" "$RESOURCES_DIR/DDS-LICENSE.txt"
chmod 755 "$MACOS_DIR/BridgeTeacherMac"
chmod 755 "$CONTENTS_DIR/Helpers/bridge-dds"

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
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>桥牌教学</string>
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

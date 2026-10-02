#!/bin/zsh
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$APP_ROOT/Scripts/release-identity.sh"

"$APP_ROOT/Scripts/build-macos-app.sh"

STAGING_DIR="$APP_ROOT/.build/macos/dmg-staging"
DMG_PATH="$APP_ROOT/.build/macos/$RELEASE_ASSET"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
ditto "$APP_ROOT/.build/macos/Bridge Coup.app" "$STAGING_DIR/Bridge Coup.app"
ln -s /Applications "$STAGING_DIR/Applications"
rm -f "$DMG_PATH"
hdiutil create -quiet -volname "Bridge Coup $RELEASE_LABEL" -srcfolder "$STAGING_DIR" -format UDZO -ov "$DMG_PATH"
rm -rf "$STAGING_DIR"
"$APP_ROOT/Scripts/verify-macos-dmg.sh" "$DMG_PATH"
print "Built $DMG_PATH"

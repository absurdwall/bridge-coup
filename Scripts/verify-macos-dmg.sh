#!/bin/zsh
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$APP_ROOT/Scripts/release-identity.sh"
DMG_PATH="${1:-$APP_ROOT/.build/macos/$RELEASE_ASSET}"
[[ -f "$DMG_PATH" ]] || { print -u2 "Missing DMG: $DMG_PATH"; exit 1; }
[[ "${DMG_PATH:t}" == "$RELEASE_ASSET" ]] || { print -u2 "DMG filename differs from declared release asset"; exit 1; }

MOUNT_DIR="$(mktemp -d /tmp/bridge-coup-dmg.XXXXXX)"
cleanup() {
  hdiutil detach -quiet "$MOUNT_DIR" >/dev/null 2>&1 || true
  rmdir "$MOUNT_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT
hdiutil attach -quiet -readonly -nobrowse -mountpoint "$MOUNT_DIR" "$DMG_PATH"

APP_BUNDLE="$MOUNT_DIR/Bridge Coup.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
[[ -d "$APP_BUNDLE" && -L "$MOUNT_DIR/Applications" &&
   "$(readlink "$MOUNT_DIR/Applications")" == /Applications ]] || {
  print -u2 "DMG must contain Bridge Coup.app and an Applications shortcut"; exit 1
}
PLIST="$CONTENTS_DIR/Info.plist"
for ENTRY in \
  "CFBundleIdentifier:app.tortillaflat.bridge-teacher" \
  "CFBundleShortVersionString:$RELEASE_VERSION" \
  "CFBundleVersion:$RELEASE_BUILD" \
  "BridgeCoupReleaseTag:$RELEASE_TAG" \
  "BridgeCoupReleaseLabel:$RELEASE_LABEL" \
  "BridgeCoupReleaseChannel:$RELEASE_CHANNEL" \
  "LSMinimumSystemVersion:14.0"; do
  KEY="${ENTRY%%:*}"
  EXPECTED="${ENTRY#*:}"
  ACTUAL="$(/usr/libexec/PlistBuddy -c "Print :$KEY" "$PLIST")"
  [[ "$ACTUAL" == "$EXPECTED" ]] || { print -u2 "$KEY: expected '$EXPECTED', found '$ACTUAL'"; exit 1; }
done

for FILE in "$CONTENTS_DIR/MacOS/BridgeTeacherMac" "$CONTENTS_DIR/Helpers/bridge-dds" "$CONTENTS_DIR/Resources/codex"; do
  [[ -x "$FILE" ]] || { print -u2 "Missing executable: $FILE"; exit 1; }
done
while IFS= read -r -d '' FILE; do
  [[ -x "$FILE" ]] || continue
  file -b "$FILE" | grep -q 'Mach-O' || {
    print -u2 "Unexpected non-Mach-O executable in app bundle: $FILE"; exit 1
  }
  ARCHS="$(lipo -archs "$FILE")"
  [[ "$ARCHS" == arm64 ]] || { print -u2 "Expected arm64 only in $FILE, found $ARCHS"; exit 1; }
  MINOS="$(vtool -show-build "$FILE" | awk '$1 == "minos" { print $2; exit }')"
  [[ -n "$MINOS" ]] || { print -u2 "Missing minimum macOS version in $FILE"; exit 1; }
  if [[ "$FILE" == "$CONTENTS_DIR/MacOS/BridgeTeacherMac" ||
        "$FILE" == "$CONTENTS_DIR/Helpers/bridge-dds" ]]; then
    [[ "$MINOS" == 14 || "$MINOS" == 14.* ]] || {
      print -u2 "Expected macOS 14 deployment target in $FILE, found $MINOS"; exit 1
    }
  else
    (( ${MINOS%%.*} <= 14 )) || {
      print -u2 "$FILE requires macOS $MINOS, above the supported macOS 14 minimum"; exit 1
    }
  fi
  codesign --verify --strict --verbose=2 "$FILE"
done < <(find "$CONTENTS_DIR" -type f -print0)
for FILE in DDS-LICENSE.txt Codex-LICENSE.txt Codex-NOTICE.txt BridgeCoup.icns BridgeCoupLogo.png BridgeCoupWordmark.png; do
  [[ -s "$CONTENTS_DIR/Resources/$FILE" ]] || { print -u2 "Missing resource: $FILE"; exit 1; }
done
for FILE in Codex-LICENSE.txt Codex-NOTICE.txt; do
  cmp "$APP_ROOT/ThirdPartyNotices/$FILE" "$CONTENTS_DIR/Resources/$FILE" || {
    print -u2 "Shipped $FILE differs from pinned source notice"; exit 1
  }
done
[[ "$("$CONTENTS_DIR/Resources/codex" --version)" == 'codex-cli 0.156.1' ]] || {
  print -u2 "Unexpected shipped Codex runtime version"; exit 1
}
"$APP_ROOT/Scripts/verify-codex-handshake.py" "$CONTENTS_DIR/Resources/codex"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
SIGNATURE="$(codesign -dv --verbose=4 "$APP_BUNDLE" 2>&1)"
[[ "$SIGNATURE" == *'Signature=adhoc'* ]] || {
  print -u2 "Expected valid ad hoc app signature"; exit 1
}
# Complete, independently known deal: each seat holds one full suit. North
# leads spades in a spade contract and DDS must find all thirteen tricks.
DEAL='0|0||AKQJT98765432...|.AKQJT98765432..|..AKQJT98765432.|...AKQJT98765432'
RESULT="$(print -r -- "$DEAL" | "$CONTENTS_DIR/Helpers/bridge-dds" --bridge-teacher-dds-wire-v1)"
[[ "$RESULT" == *'"tricks":13'* ]] || {
  print -u2 "Packaged DDS helper did not solve the complete deal as expected: $RESULT"; exit 1
}
print "Verified $DMG_PATH ($RELEASE_LABEL, build $RELEASE_BUILD, arm64, macOS 14+)"

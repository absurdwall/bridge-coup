#!/bin/zsh
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$APP_ROOT/Scripts/codex-runtime-identity.sh"
ARCHIVE_URL="https://github.com/openai/codex/releases/download/rust-v${CODEX_BUNDLED_RUNTIME_VERSION}/${CODEX_BUNDLED_RUNTIME_ARCHIVE}"
CACHE_DIR="$APP_ROOT/.build/codex-runtime"
ARCHIVE="$CACHE_DIR/$CODEX_BUNDLED_RUNTIME_ARCHIVE"
EXECUTABLE="$CACHE_DIR/codex"
mkdir -p "$CACHE_DIR"

if [[ ! -f "$ARCHIVE" ]]; then
  TEMP_ARCHIVE="$(mktemp "$CACHE_DIR/codex-download.XXXXXX")"
  trap 'rm -f "$TEMP_ARCHIVE"' EXIT
  curl --fail --location --silent --show-error --retry 3 "$ARCHIVE_URL" -o "$TEMP_ARCHIVE"
  mv "$TEMP_ARCHIVE" "$ARCHIVE"
fi

ACTUAL_SHA256="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
[[ "$ACTUAL_SHA256" == "$CODEX_BUNDLED_RUNTIME_SHA256" ]] || {
  print -u2 "Codex archive checksum mismatch: expected $CODEX_BUNDLED_RUNTIME_SHA256, found $ACTUAL_SHA256"
  exit 1
}
[[ "$(tar -tzf "$ARCHIVE")" == codex-aarch64-apple-darwin ]] || {
  print -u2 "Unexpected Codex archive contents"
  exit 1
}
tar -xzf "$ARCHIVE" -C "$CACHE_DIR" codex-aarch64-apple-darwin
mv "$CACHE_DIR/codex-aarch64-apple-darwin" "$EXECUTABLE"
chmod 755 "$EXECUTABLE"
[[ "$(lipo -archs "$EXECUTABLE")" == arm64 ]] || { print -u2 "Codex is not arm64-only"; exit 1; }
[[ "$($EXECUTABLE --version)" == "codex-cli $CODEX_BUNDLED_RUNTIME_VERSION" ]] || { print -u2 "Unexpected Codex version"; exit 1; }
MINOS="$(vtool -show-build "$EXECUTABLE" | awk '$1 == "minos" { print $2; exit }')"
[[ -n "$MINOS" && "${MINOS%%.*}" -le 14 ]] || { print -u2 "Codex requires macOS $MINOS"; exit 1; }
codesign --verify --strict "$EXECUTABLE"
if otool -L "$EXECUTABLE" | tail -n +2 | awk '{print $1}' | grep -Ev '^(/usr/lib/|/System/Library/)' ; then
  print -u2 "Codex depends on a library outside system paths"
  exit 1
fi
print "$EXECUTABLE"

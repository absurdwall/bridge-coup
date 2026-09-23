#!/bin/zsh
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_ROOT"

DDS_TAG="v3.0.0"
DDS_COMMIT="37c8a79f4c67c55d1a309ccb66dd00cb58af464a"
BAZELISK_VERSION="1.29.0"
BAZEL_VERSION="9.2.0"
TOOLS_DIR="$APP_ROOT/.build/dds-tools"
SOURCE_DIR="$APP_ROOT/.build/dds-source-v3.0.0"
BAZEL_OUTPUT_ROOT="$APP_ROOT/.build/dds-bazel-output"
OUTPUT_DIR="$APP_ROOT/.build/dds"

case "$(uname -m)" in
  arm64)
    BAZELISK_ARCH="arm64"
    BAZELISK_SHA256="cee851f726789227d5561004e9904a52be45c3efb56f8b38b6993d6adbaa0409"
    ;;
  x86_64)
    BAZELISK_ARCH="amd64"
    BAZELISK_SHA256="16c3d7aa15323a9fb69f56c7ec5733ed18bedb786680d0ba13bb12a3c8083007"
    ;;
  *)
    print -u2 "Unsupported macOS architecture: $(uname -m)"
    exit 1
    ;;
esac

mkdir -p "$TOOLS_DIR" "$OUTPUT_DIR"
BAZELISK="$TOOLS_DIR/bazelisk"
BAZELISK_URL="https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-darwin-${BAZELISK_ARCH}"

if [[ ! -f "$BAZELISK" ]]; then
  TEMP_BINARY="$TOOLS_DIR/bazelisk.download"
  curl --fail --location --silent --show-error "$BAZELISK_URL" -o "$TEMP_BINARY"
  ACTUAL_SHA256="$(shasum -a 256 "$TEMP_BINARY" | awk '{print $1}')"
  if [[ "$ACTUAL_SHA256" != "$BAZELISK_SHA256" ]]; then
    rm -f "$TEMP_BINARY"
    print -u2 "Bazelisk checksum mismatch: expected $BAZELISK_SHA256, got $ACTUAL_SHA256"
    exit 1
  fi
  mv "$TEMP_BINARY" "$BAZELISK"
  chmod 755 "$BAZELISK"
fi

ACTUAL_SHA256="$(shasum -a 256 "$BAZELISK" | awk '{print $1}')"
if [[ "$ACTUAL_SHA256" != "$BAZELISK_SHA256" ]]; then
  print -u2 "Pinned Bazelisk binary has an unexpected checksum. Remove only $BAZELISK to redownload it."
  exit 1
fi

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  git clone --filter=blob:none --depth 1 --branch "$DDS_TAG" https://github.com/dds-bridge/dds.git "$SOURCE_DIR"
fi
ACTUAL_COMMIT="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
if [[ "$ACTUAL_COMMIT" != "$DDS_COMMIT" ]]; then
  print -u2 "DDS $DDS_TAG resolved to $ACTUAL_COMMIT; expected $DDS_COMMIT. Refusing to replace the source checkout."
  exit 1
fi

HELPER_TARGET="$SOURCE_DIR/BridgeTeacherHelper"
mkdir -p "$HELPER_TARGET"
cp "$APP_ROOT/Native/DDSHelper/BUILD.bazel" "$HELPER_TARGET/BUILD.bazel"
cp "$APP_ROOT/Native/DDSHelper/bridge_teacher_dds.cpp" "$HELPER_TARGET/bridge_teacher_dds.cpp"

(
  cd "$SOURCE_DIR"
  USE_BAZEL_VERSION="$BAZEL_VERSION" "$BAZELISK" \
    --output_user_root="$BAZEL_OUTPUT_ROOT" \
    build --repository_cache="$APP_ROOT/.build/dds-repository-cache" \
    --compilation_mode=opt --jobs="$(sysctl -n hw.ncpu)" \
    //BridgeTeacherHelper:bridge_teacher_dds
)

BUILT_HELPER="$SOURCE_DIR/bazel-bin/BridgeTeacherHelper/bridge_teacher_dds"
if [[ ! -x "$BUILT_HELPER" ]]; then
  print -u2 "Bazel build succeeded but did not produce $BUILT_HELPER"
  exit 1
fi
install -m 755 "$BUILT_HELPER" "$OUTPUT_DIR/bridge-dds"
print "Built DDS $DDS_TAG ($DDS_COMMIT) at $OUTPUT_DIR/bridge-dds"

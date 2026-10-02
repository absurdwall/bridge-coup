# Sourced by package scripts; APP_ROOT must already identify this checkout.
RELEASE_FILE="${BRIDGE_COUP_RELEASE_FILE:-$APP_ROOT/Release/release.env}"
[[ "$RELEASE_FILE" == /* ]] || { print -u2 "Release identity path must be absolute: $RELEASE_FILE"; exit 1; }
[[ -f "$RELEASE_FILE" ]] || { print -u2 "Missing release identity: $RELEASE_FILE"; exit 1; }
source "$RELEASE_FILE"

if [[ ! "$RELEASE_VERSION" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ||
      ! "$RELEASE_BUILD" =~ '^[1-9][0-9]*$' ||
      "$RELEASE_ASSET" != "Bridge-Coup-${RELEASE_TAG}-arm64.dmg" ]]; then
  print -u2 "Invalid release identity in $RELEASE_FILE"
  exit 1
fi
case "$RELEASE_CHANNEL" in
  beta)
    if [[ ! "$RELEASE_BETA_NUMBER" =~ '^[1-9][0-9]*$' ||
          "$RELEASE_TAG" != "v${RELEASE_VERSION}-beta.${RELEASE_BETA_NUMBER}" ||
          "$RELEASE_LABEL" != "${RELEASE_VERSION} Beta ${RELEASE_BETA_NUMBER}" ]]; then
      print -u2 "Beta tag or label differs from the declared version and beta number"
      exit 1
    fi
    ;;
  stable)
    if [[ "$RELEASE_TAG" != "v${RELEASE_VERSION}" ||
          "$RELEASE_LABEL" != "$RELEASE_VERSION" ]]; then
      print -u2 "Stable tag or label differs from the declared version"
      exit 1
    fi
    ;;
  *)
    print -u2 "Unsupported release channel: $RELEASE_CHANNEL"
    exit 1
    ;;
esac

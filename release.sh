#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
VERSION="$(cd "$ROOT" && node -p "require('./package.json').version")"
SOURCE_COMMIT="$(git -C "$ROOT" rev-parse HEAD)"
BUILD_TIME="${BUILD_TIME:-$(date -u '+%Y-%m-%dT%H:%M:%SZ')}"
CORE_COMMIT="${CORE_COMMIT:?set CORE_COMMIT to the exact core release commit}"
case "$CORE_COMMIT" in ????????*) ;; *) printf '%s\n' 'CORE_COMMIT must identify a Git commit' >&2; exit 2 ;; esac
OUT="$ROOT/releases/ruijie-panel-${VERSION}.tar.gz"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/ruijie-panel/api" "$STAGE/ruijie-panel/init.d" "$STAGE/ruijie-panel/dist"
cp "$ROOT"/dist/* "$STAGE/ruijie-panel/dist/"
cp "$ROOT"/api/*.sh "$STAGE/ruijie-panel/api/"
cp "$ROOT"/init.d/ruijie-panel "$STAGE/ruijie-panel/init.d/"
cp "$ROOT"/install.sh "$ROOT"/uninstall.sh "$STAGE/ruijie-panel/"
chmod 755 "$STAGE/ruijie-panel"/api/*.sh "$STAGE/ruijie-panel/init.d/ruijie-panel" \
    "$STAGE/ruijie-panel/install.sh" "$STAGE/ruijie-panel/uninstall.sh"
printf 'core_version=4.0.0\ncore_api_schema=2\ncore_commit=%s\npanel_api_schema=2\n' "$CORE_COMMIT" > "$STAGE/ruijie-panel/compatibility.conf"
printf 'component=panel\nversion=%s\nsource_commit=%s\nbuild_time=%s\napi_schema=2\n' \
    "$VERSION" "$SOURCE_COMMIT" "$BUILD_TIME" > "$STAGE/ruijie-panel/build-info.conf"
(cd "$STAGE/ruijie-panel" && find . -type f ! -name manifest.sha256 -print0 | sort -z | xargs -0 sha256sum > manifest.sha256)
mkdir -p "$ROOT/releases"
tar -C "$STAGE" -czf "$OUT" ruijie-panel
printf '%s\n' "$OUT"

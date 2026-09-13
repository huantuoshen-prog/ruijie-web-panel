#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
VERSION="$(node -p "require('./package.json').version")"
OUT="$ROOT/releases/ruijie-panel-${VERSION}.tar.gz"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/ruijie-panel/api" "$STAGE/ruijie-panel/init.d" "$STAGE/ruijie-panel/dist"
cp "$ROOT"/dist/* "$STAGE/ruijie-panel/dist/"
cp "$ROOT"/api/*.sh "$STAGE/ruijie-panel/api/"
cp "$ROOT"/init.d/ruijie-panel "$STAGE/ruijie-panel/init.d/"
cp "$ROOT"/install.sh "$ROOT"/uninstall.sh "$STAGE/ruijie-panel/"
printf '%s\n' 'core_version=4.0.0' 'core_api_schema=2' 'panel_api_schema=2' > "$STAGE/ruijie-panel/compatibility.conf"
(cd "$STAGE/ruijie-panel" && find . -type f ! -name manifest.sha256 -print0 | sort -z | xargs -0 sha256sum > manifest.sha256)
mkdir -p "$ROOT/releases"
tar -C "$STAGE" -czf "$OUT" ruijie-panel
printf '%s\n' "$OUT"

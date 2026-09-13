#!/bin/sh
# Combine already-built, version-pinned core and panel archives for offline transfer.
set -eu
CORE_ARCHIVE="${1:?usage: combine-release.sh CORE_ARCHIVE PANEL_ARCHIVE}"
PANEL_ARCHIVE="${2:?usage: combine-release.sh CORE_ARCHIVE PANEL_ARCHIVE}"
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
OUT="$ROOT/releases/ruijie-openwrt-bundle.tar.gz"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/ruijie-openwrt-bundle"
cp "$CORE_ARCHIVE" "$STAGE/ruijie-openwrt-bundle/core.tar.gz"
cp "$PANEL_ARCHIVE" "$STAGE/ruijie-openwrt-bundle/panel.tar.gz"
(cd "$STAGE/ruijie-openwrt-bundle" && sha256sum core.tar.gz panel.tar.gz > manifest.sha256)
cat > "$STAGE/ruijie-openwrt-bundle/README" <<'EOF'
Install core.tar.gz first, then panel.tar.gz. Verify each inner manifest before installing.
The panel compatibility file pins core 4.0.0 and API schema 2.
EOF
mkdir -p "$ROOT/releases"
tar -C "$STAGE" -czf "$OUT" ruijie-openwrt-bundle
printf '%s\n' "$OUT"

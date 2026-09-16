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
core_commit="$(tar -xOzf "$CORE_ARCHIVE" ruijie-core/build-info.conf | sed -n 's/^source_commit=//p')"
panel_core_commit="$(tar -xOzf "$PANEL_ARCHIVE" ruijie-panel/compatibility.conf | sed -n 's/^core_commit=//p')"
[ -n "$core_commit" ] && [ "$core_commit" = "$panel_core_commit" ] || {
    printf '%s\n' 'core and panel archives do not declare the same source commit' >&2
    exit 1
}
cat > "$STAGE/ruijie-openwrt-bundle/README" <<'EOF'
Install core.tar.gz first, then panel.tar.gz. Verify each inner manifest before installing.
The panel compatibility file pins the exact core commit and API schema 2.
EOF
printf 'core_source_commit=%s\n' "$core_commit" > "$STAGE/ruijie-openwrt-bundle/build-info.conf"
(cd "$STAGE/ruijie-openwrt-bundle" && find . -type f -print0 | sort -z | xargs -0 sha256sum > manifest.sha256)
mkdir -p "$ROOT/releases"
tar -C "$STAGE" -czf "$OUT" ruijie-openwrt-bundle
printf '%s\n' "$OUT"

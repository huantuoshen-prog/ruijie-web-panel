#!/bin/sh
# Install only from an extracted, checksummed panel release bundle.
set -eu
SOURCE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
MANIFEST="$SOURCE_DIR/manifest.sha256"
TARGET=/overlay/usr/www/ruijie-web
[ -d /overlay ] || TARGET=/www/ruijie-web
STAGE="${TARGET}.next.$$"
BACKUP="${TARGET}.rollback"
PREVIOUS_INIT="${BACKUP}.init"
AUTH_FILE=/etc/ruijie-panel/auth.conf

fail() { printf '%s\n' "panel install failed: $*" >&2; exit 1; }
[ -f /etc/config/uhttpd ] || fail 'uhttpd is required'
[ -x /etc/ruijie/ruijiectl ] || fail 'core 4.x must be installed before the panel'
for command in jq sha256sum curl uci; do command -v "$command" >/dev/null 2>&1 || fail "missing dependency: $command"; done
LAN_IP="$(uci get network.lan.ipaddr 2>/dev/null)" || fail 'LAN address is unavailable'
[ -n "$LAN_IP" ] && [ "$LAN_IP" != '0.0.0.0' ] || fail 'a specific LAN address is required'
[ -f "$MANIFEST" ] || fail 'manifest.sha256 is missing; use a fixed release bundle'
(cd "$SOURCE_DIR" && sha256sum -c manifest.sha256) || fail 'bundle checksum verification failed'

# An upgrade retains the existing password. A first install must create one
# before exposing the management endpoint. Tests and unattended installs may
# supply PANEL_PASSWORD; normal use reads it without echoing it.
new_password=''
if [ ! -f "$AUTH_FILE" ]; then
    if [ -n "${PANEL_PASSWORD:-}" ]; then
        new_password="$PANEL_PASSWORD"
    elif [ -t 0 ]; then
        printf '%s' 'Create the Web panel password: ' >&2
        stty -echo
        IFS= read -r new_password
        stty echo
        printf '\n' >&2
        printf '%s' 'Confirm the Web panel password: ' >&2
        stty -echo
        IFS= read -r confirmation
        stty echo
        printf '\n' >&2
        [ "$new_password" = "$confirmation" ] || fail 'password confirmation did not match'
    else
        fail 'first install needs a panel password; run interactively or set PANEL_PASSWORD in the install environment'
    fi
    [ -n "$new_password" ] || fail 'panel password cannot be empty'
    if printf '%s' "$new_password" | LC_ALL=C grep -q '[[:cntrl:]]'; then
        fail 'panel password cannot contain control characters'
    fi
fi

mkdir -p "$STAGE/api" "$STAGE/ruijie-cgi"
cp "$SOURCE_DIR"/dist/* "$STAGE/"
cp "$SOURCE_DIR"/api/*.sh "$STAGE/api/"
cp "$SOURCE_DIR/uninstall.sh" "$STAGE/"
for name in auth auth-action account daemon health health-log log mode runtime settings status; do
    ln -s "../api/${name}.sh" "$STAGE/ruijie-cgi/$name"
done
chmod 755 "$STAGE"/api/*.sh "$STAGE/uninstall.sh"

was_running=false
[ -x /etc/init.d/ruijie-panel ] && /etc/init.d/ruijie-panel running >/dev/null 2>&1 && was_running=true
[ -d "$TARGET" ] && {
    rm -rf "$BACKUP" "$PREVIOUS_INIT"
    mv "$TARGET" "$BACKUP"
    [ -f /etc/init.d/ruijie-panel ] && cp -p /etc/init.d/ruijie-panel "$PREVIOUS_INIT" || true
}
mv "$STAGE" "$TARGET"
cp "$SOURCE_DIR/init.d/ruijie-panel" /etc/init.d/ruijie-panel
chmod 755 /etc/init.d/ruijie-panel
/etc/init.d/ruijie-panel enable
if [ "$was_running" = true ]; then
    /etc/init.d/ruijie-panel restart
else
    /etc/init.d/ruijie-panel start
fi || {
    [ -d "$BACKUP" ] && {
        rm -rf "$TARGET"
        mv "$BACKUP" "$TARGET"
        [ -f "$PREVIOUS_INIT" ] && cp "$PREVIOUS_INIT" /etc/init.d/ruijie-panel || rm -f /etc/init.d/ruijie-panel
        /etc/init.d/ruijie-panel start || true
    }
    fail 'panel service did not start; previous panel restored'
}
health_ok=false
health_attempt=0
while [ "$health_attempt" -lt 10 ]; do
    if curl --noproxy '*' -fsS --max-time 2 "http://${LAN_IP}:8080/ruijie-cgi/auth" >/dev/null 2>&1; then
        health_ok=true
        break
    fi
    health_attempt=$((health_attempt + 1))
    sleep 1
done
[ "$health_ok" = true ] || {
    /etc/init.d/ruijie-panel stop || true
    [ -d "$BACKUP" ] && {
        rm -rf "$TARGET"
        mv "$BACKUP" "$TARGET"
        [ -f "$PREVIOUS_INIT" ] && cp "$PREVIOUS_INIT" /etc/init.d/ruijie-panel || rm -f /etc/init.d/ruijie-panel
        /etc/init.d/ruijie-panel start || true
    }
    fail 'health check failed; previous panel restored'
}
if [ -n "$new_password" ]; then
    mkdir -p /etc/ruijie-panel || fail 'could not create panel authentication directory'
    umask 077
    printf 'PASSWORD_SHA256=%s\n' "$(printf '%s' "$new_password" | sha256sum | awk '{print $1}')" > "$AUTH_FILE" \
        && chmod 600 "$AUTH_FILE" || fail 'could not save panel password'
fi
printf '%s\n' "panel installed at $TARGET; previous release kept at $BACKUP"

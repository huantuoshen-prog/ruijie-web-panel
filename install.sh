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
ROLLBACK_META="${BACKUP}.state"
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

mkdir -p "$STAGE/api" "$STAGE/init.d" "$STAGE/ruijie-cgi"
cp "$SOURCE_DIR"/dist/* "$STAGE/"
cp "$SOURCE_DIR"/api/*.sh "$STAGE/api/"
cp "$SOURCE_DIR/init.d/ruijie-panel" "$STAGE/init.d/"
cp "$SOURCE_DIR/uninstall.sh" "$SOURCE_DIR/rollback.sh" "$STAGE/"
for name in auth auth-action account daemon health health-log log mode runtime settings status; do
    ln -s "../api/${name}.sh" "$STAGE/ruijie-cgi/$name"
done
chmod 755 "$STAGE"/api/*.sh "$STAGE/init.d/ruijie-panel" "$STAGE/uninstall.sh" "$STAGE/rollback.sh"

existing_install=false
service_enabled=true
service_running=true
init_present=false
if [ -d "$TARGET" ] || [ -f /etc/init.d/ruijie-panel ]; then
    existing_install=true
    service_enabled=false
    service_running=false
    [ -f /etc/init.d/ruijie-panel ] && init_present=true
    [ -x /etc/init.d/ruijie-panel ] && /etc/init.d/ruijie-panel enabled >/dev/null 2>&1 && service_enabled=true
    uci -q get uhttpd.ruijie >/dev/null 2>&1 && service_running=true
fi
[ -d "$TARGET" ] && {
    rm -rf "$BACKUP" "$PREVIOUS_INIT" "$ROLLBACK_META"
    mv "$TARGET" "$BACKUP"
    [ -f /etc/init.d/ruijie-panel ] && cp -p /etc/init.d/ruijie-panel "$PREVIOUS_INIT" || true
    printf 'enabled=%s\nrunning=%s\ninit_present=%s\n' \
        "$service_enabled" "$service_running" "$init_present" > "$ROLLBACK_META"
}
mv "$STAGE" "$TARGET"
cp "$SOURCE_DIR/init.d/ruijie-panel" /etc/init.d/ruijie-panel
chmod 755 /etc/init.d/ruijie-panel

auth_created=false
restore_previous_release() {
    /etc/init.d/ruijie-panel stop || true
    /etc/init.d/ruijie-panel disable || true
    rm -rf "$TARGET"
    if [ -d "$BACKUP" ]; then
        mv "$BACKUP" "$TARGET"
        if [ "$init_present" = true ] && [ -f "$PREVIOUS_INIT" ]; then
            cp "$PREVIOUS_INIT" /etc/init.d/ruijie-panel
            chmod 755 /etc/init.d/ruijie-panel
        else
            rm -f /etc/init.d/ruijie-panel
        fi
        if [ -x /etc/init.d/ruijie-panel ]; then
            [ "$service_enabled" = true ] && /etc/init.d/ruijie-panel enable || /etc/init.d/ruijie-panel disable || true
            [ "$service_running" = true ] && /etc/init.d/ruijie-panel start || true
        fi
    else
        rm -f /etc/init.d/ruijie-panel
    fi
    if [ "$auth_created" = true ]; then
        rm -f "$AUTH_FILE"
    fi
}

if [ -n "$new_password" ]; then
    mkdir -p /etc/ruijie-panel || { restore_previous_release; fail 'could not create panel authentication directory'; }
    umask 077
    auth_tmp="${AUTH_FILE}.tmp.$$"
    if printf 'PASSWORD_SHA256=%s\n' "$(printf '%s' "$new_password" | sha256sum | awk '{print $1}')" > "$auth_tmp" \
        && chmod 600 "$auth_tmp" && mv -f "$auth_tmp" "$AUTH_FILE"; then
        auth_created=true
    else
        rm -f "$auth_tmp"
        restore_previous_release
        fail 'could not save panel password'
    fi
fi

[ "$service_enabled" = true ] && /etc/init.d/ruijie-panel enable || /etc/init.d/ruijie-panel disable
if ! /etc/init.d/ruijie-panel start; then
    restore_previous_release
    fail 'panel service did not start; previous panel restored'
fi

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
if [ "$health_ok" != true ]; then
    restore_previous_release
    fail 'health check failed; previous panel restored'
fi

if [ "$existing_install" = true ] && [ "$service_running" != true ]; then
    if ! /etc/init.d/ruijie-panel stop; then
        restore_previous_release
        fail 'could not restore the previous stopped state'
    fi
fi
printf '%s\n' "panel installed at $TARGET; previous release and service state kept at $BACKUP"

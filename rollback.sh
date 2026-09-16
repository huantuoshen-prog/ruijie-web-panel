#!/bin/sh
# Restore the previous verified panel release and its service state.
set -eu

TARGET=/overlay/usr/www/ruijie-web
[ -d /overlay ] || TARGET=/www/ruijie-web
ROLLBACK="${TARGET}.rollback"
ROLLBACK_META="${ROLLBACK}.state"
PREVIOUS_INIT="${ROLLBACK}.init"

[ -d "$ROLLBACK" ] || { printf '%s\n' 'no panel rollback release is available' >&2; exit 1; }
enabled=false
running=false
init_present=false
[ -f "$ROLLBACK_META" ] && . "$ROLLBACK_META"

[ -x /etc/init.d/ruijie-panel ] && /etc/init.d/ruijie-panel stop || true
FAILED="${TARGET}.failed.$(date +%s).$$"
mv "$TARGET" "$FAILED"
mv "$ROLLBACK" "$TARGET"
if [ "$init_present" = true ] && [ -f "$PREVIOUS_INIT" ]; then
    cp "$PREVIOUS_INIT" /etc/init.d/ruijie-panel
elif [ "$init_present" = true ] && [ -f "$TARGET/init.d/ruijie-panel" ]; then
    cp "$TARGET/init.d/ruijie-panel" /etc/init.d/ruijie-panel
else
    rm -f /etc/init.d/ruijie-panel
fi
[ -x /etc/init.d/ruijie-panel ] || {
    printf '%s\n' "rollback restored files but no service script; failed files kept at $FAILED" >&2
    exit 1
}
chmod 755 /etc/init.d/ruijie-panel
[ "$enabled" = true ] && /etc/init.d/ruijie-panel enable || /etc/init.d/ruijie-panel disable
/etc/init.d/ruijie-panel start

LAN_IP="$(uci get network.lan.ipaddr 2>/dev/null)" || {
    printf '%s\n' "rollback restored files but the LAN address is unavailable; failed files kept at $FAILED" >&2
    exit 1
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
    printf '%s\n' "rollback health check failed; failed files kept at $FAILED" >&2
    exit 1
}
[ "$running" = true ] || /etc/init.d/ruijie-panel stop
rm -f "$ROLLBACK_META" "$PREVIOUS_INIT"
printf '%s\n' "panel rollback complete; replaced files kept at $FAILED"

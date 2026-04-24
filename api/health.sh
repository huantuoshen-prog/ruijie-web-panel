#!/bin/sh
# ========================================
# API: 健康监听状态与控制
# GET  /ruijie-cgi/health
# POST /ruijie-cgi/health
# ========================================

. "$(dirname "$0")/../api/common.sh"

panel_require_auth || exit 0

echo "Content-Type: application/json; charset=utf-8"
echo ""

SCRIPT_DIR=$(find_ruijie_dir)
if [ -z "$SCRIPT_DIR" ]; then
    printf '{"supported":false,"message":"锐捷脚本未安装"}'
    exit 0
fi

. "${SCRIPT_DIR}/lib/common.sh" 2>/dev/null
. "${SCRIPT_DIR}/lib/config.sh" 2>/dev/null

if [ ! -f "${SCRIPT_DIR}/lib/health.sh" ]; then
    printf '{"supported":false,"message":"主脚本版本过低，需升级后使用"}'
    exit 0
fi

. "${SCRIPT_DIR}/lib/health.sh" 2>/dev/null

METHOD="${REQUEST_METHOD:-GET}"

if [ "$METHOD" = "POST" ]; then
    _body=$(read_post_body)
    _action=$(urldecode "$(body_get_field "action" "$_body")")
    _duration=$(urldecode "$(body_get_field "duration" "$_body")")

    case "$_action" in
        enable)
            case "$_duration" in
                1d|3d|7d|permanent) ;;
                *) _duration="3d" ;;
            esac
            health_enable "$_duration"
            ;;
        disable)
            health_disable
            ;;
        *)
            printf '{"success":false,"message":"未知操作，请使用 enable 或 disable"}'
            exit 0
            ;;
    esac
fi

health_expire_if_needed >/dev/null 2>&1 || true
health_write_runtime_snapshot >/dev/null 2>&1 || true
health_write_status_snapshot >/dev/null 2>&1 || true

if [ -f "${HEALTH_STATUS_FILE:-/var/run/ruijie-health.status.json}" ]; then
    cat "${HEALTH_STATUS_FILE:-/var/run/ruijie-health.status.json}"
else
    health_load_config
    printf '{"supported":true,'
    printf '"enabled":%s,' "$(json_bool "${HEALTH_MONITOR_ENABLED:-false}")"
    printf '"mode":"%s",' "$(json_esc "${HEALTH_MONITOR_MODE:-timed}")"
    printf '"until":"%s",' "$(json_esc "${HEALTH_MONITOR_UNTIL:-}")"
    printf '"remaining_seconds":%s,' "$(json_num_or_null "$(health_remaining_seconds)")"
    printf '"collector_active":%s,' "$(json_bool "$(health_collector_active)")"
    printf '"baseline_interval":%s,' "$(json_num_or_null "${HEALTH_MONITOR_BASELINE_INTERVAL:-900}")"
    printf '"redaction":"%s",' "$(json_esc "${HEALTH_MONITOR_REDACTION:-mask_password_and_session_only}")"
    printf '"last_event_at":"",'
    printf '"snapshot":%s}' "$(health_snapshot_json)"
fi

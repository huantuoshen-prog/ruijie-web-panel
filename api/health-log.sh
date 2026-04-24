#!/bin/sh
# ========================================
# API: 健康监听日志
# GET /ruijie-cgi/health-log
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

if [ ! -f "${SCRIPT_DIR}/lib/health.sh" ]; then
    printf '{"supported":false,"message":"主脚本版本过低，需升级后使用"}'
    exit 0
fi

. "${SCRIPT_DIR}/lib/health.sh" 2>/dev/null

_lines=$(urldecode "$(query_get_field "lines")")
_level=$(urldecode "$(query_get_field "level")")
_type=$(urldecode "$(query_get_field "type")")

case "$_lines" in
    ''|*[!0-9]*) _lines="100" ;;
esac

health_log_json "$_lines" "$_level" "$_type"

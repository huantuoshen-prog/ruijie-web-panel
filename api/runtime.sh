#!/bin/sh
# ========================================
# API: 运行环境摘要
# GET /ruijie-cgi/runtime
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

if [ ! -f "${SCRIPT_DIR}/lib/health.sh" ]; then
    printf '{"supported":false,"message":"主脚本版本过低，需升级后使用"}'
    exit 0
fi

. "${SCRIPT_DIR}/lib/health.sh" 2>/dev/null

health_write_runtime_snapshot >/dev/null 2>&1 || true
_runtime_json="$(health_runtime_json)"
printf '{"supported":true,%s' "${_runtime_json#\{}"

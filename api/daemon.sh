#!/bin/sh
# ========================================
# API: 守护进程控制
# POST /ruijie-cgi/daemon
# body: action=start|stop|restart（application/x-www-form-urlencoded）
# ========================================

. "$(dirname "$0")/../api/common.sh"

panel_require_auth || exit 0

echo "Content-Type: application/json; charset=utf-8"
echo ""

SCRIPT_DIR=$(find_ruijie_dir)
if [ -z "$SCRIPT_DIR" ]; then
    printf '{"success":false,"message":"锐捷脚本未安装"}'
    exit 0
fi

. "${SCRIPT_DIR}/lib/common.sh" 2>/dev/null
. "${SCRIPT_DIR}/lib/config.sh" 2>/dev/null
. "${SCRIPT_DIR}/lib/daemon.sh" 2>/dev/null

_body=$(read_post_body)
_action=$(body_get_field "action" "$_body")

case "$_action" in
    start)
        load_config
        if daemon_start >/dev/null 2>&1; then
            _pid=$(cat "$PIDFILE" 2>/dev/null)
            _msg=$(json_esc "守护进程已启动")
            printf '{"success":true,"pid":"%s","message":"%s"}' "$_pid" "$_msg"
        else
            _msg=$(json_esc "启动失败，守护进程可能已在运行")
            printf '{"success":false,"message":"%s"}' "$_msg"
        fi
        ;;
    stop)
        daemon_stop >/dev/null 2>&1
        _msg=$(json_esc "守护进程已停止")
        printf '{"success":true,"message":"%s"}' "$_msg"
        ;;
    restart)
        daemon_stop >/dev/null 2>&1
        sleep 1
        load_config
        if daemon_start >/dev/null 2>&1; then
            _pid=$(cat "$PIDFILE" 2>/dev/null)
            _msg=$(json_esc "守护进程已重启")
            printf '{"success":true,"pid":"%s","message":"%s"}' "$_pid" "$_msg"
        else
            _msg=$(json_esc "重启失败")
            printf '{"success":false,"message":"%s"}' "$_msg"
        fi
        ;;
    *)
        _msg=$(json_esc "未知操作，请使用 start/stop/restart")
        printf '{"success":false,"message":"%s"}' "$_msg"
        ;;
esac

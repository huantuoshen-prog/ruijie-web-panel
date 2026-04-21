#!/bin/sh
. "$(dirname "$0")/../api/common.sh"
# ========================================
# API: 获取系统状态
# GET /ruijie-cgi/status
# ========================================

panel_require_auth || exit 0

echo "Content-Type: application/json; charset=utf-8"
echo ""

SCRIPT_DIR=$(find_ruijie_dir)
if [ -z "$SCRIPT_DIR" ]; then
    printf '{"installed":false,"online":false,"message":"锐捷脚本未安装，请先运行安装脚本"}'
    exit 0
fi

. "${SCRIPT_DIR}/lib/common.sh" 2>/dev/null
. "${SCRIPT_DIR}/lib/config.sh" 2>/dev/null
. "${SCRIPT_DIR}/lib/daemon.sh" 2>/dev/null
. "${SCRIPT_DIR}/lib/network.sh" 2>/dev/null

load_config

# 获取网络状态
online=false
if check_network 2>/dev/null; then
    online=true
fi

# 获取守护进程状态
daemon_running=false
daemon_pid=""
daemon_uptime=""
daemon_state=""
if daemon_is_running 2>/dev/null; then
    daemon_running=true
    daemon_pid=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$daemon_pid" ] && [ -d "/proc/$daemon_pid" ]; then
        # 使用 /proc/uptime 和 /proc/<pid>/stat 计算运行时间
        # 兼容 BusyBox ps（不支持 -o lstart=）
        _uptime_sec=$(awk '{print int($1)}' /proc/uptime 2>/dev/null)
        _start_jiffies=$(awk '{print $22}' /proc/$daemon_pid/stat 2>/dev/null)
        if [ -n "$_uptime_sec" ] && [ -n "$_start_jiffies" ]; then
            # HZ 通常为 100（Jiffies 每秒）
            # 运行时间 = 系统已运行秒数 - 进程启动偏移
            _diff=$((_uptime_sec - _start_jiffies / 100))
            if [ "$_diff" -gt 0 ] 2>/dev/null; then
                if [ "$_diff" -lt 60 ]; then
                    daemon_uptime="${_diff}秒"
                elif [ "$_diff" -lt 3600 ]; then
                    daemon_uptime="$((_diff / 60))分钟"
                else
                    daemon_uptime="$((_diff / 3600))小时$(((_diff % 3600) / 60))分钟"
                fi
            fi
        fi
    fi
    if [ -f /var/run/ruijie-daemon.state ]; then
        daemon_state=$(cat /var/run/ruijie-daemon.state 2>/dev/null)
    fi
fi

# 获取上次认证时间
last_auth=""
if _last=$(get_last_auth_time 2>/dev/null); then
    last_auth="$_last"
fi

# 输出 JSON（所有字段值经过转义）
printf '{"installed":true,'
printf '"online":%s,' "$online"
printf '"username":"%s",' "$(json_esc "${USERNAME:-}")"
printf '"operator":"%s",' "$(json_esc "${OPERATOR:-DianXin}")"
printf '"account_type":"%s",' "$(json_esc "${ACCOUNT_TYPE:-student}")"
printf '"daemon_running":%s,' "$daemon_running"
printf '"daemon_pid":"%s",' "${daemon_pid:-}"
printf '"daemon_uptime":"%s",' "${daemon_uptime:-}"
printf '"daemon_state":"%s",' "$(json_esc "${daemon_state:-}")"
printf '"last_auth":"%s",' "$(json_esc "${last_auth:-}")"
printf '"version":"%s",' "$(json_esc "${RUIJIE_VERSION:-3.1}")"
printf '"message":""}'

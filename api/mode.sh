#!/bin/sh
# ========================================
# API: 网络模式切换
# POST /ruijie-cgi/mode
# body: operator=DianXin|LianTong（application/x-www-form-urlencoded）
# ========================================

. "$(dirname "$0")/common.sh"

echo "Content-Type: application/json; charset=utf-8"
echo ""

SCRIPT_DIR=$(find_ruijie_dir)
if [ -z "$SCRIPT_DIR" ]; then
    _msg=$(json_esc "锐捷脚本未安装")
    printf '{"success":false,"message":"%s"}' "$_msg"
    exit 0
fi

. "${SCRIPT_DIR}/lib/common.sh" 2>/dev/null
. "${SCRIPT_DIR}/lib/config.sh" 2>/dev/null
. "${SCRIPT_DIR}/lib/network.sh" 2>/dev/null

_body=$(read_post_body)
_operator=$(body_get_field "operator" "$_body")

if [ "$_operator" != "DianXin" ] && [ "$_operator" != "LianTong" ]; then
    _msg=$(json_esc "运营商参数无效，请使用 DianXin 或 LianTong")
    printf '{"success":false,"message":"%s"}' "$_msg"
    exit 0
fi

load_config

_cfg_tmp=$(mktemp)
if sed "s/^OPERATOR=.*/OPERATOR=$_operator/" "$CONFIG_FILE" > "$_cfg_tmp" 2>/dev/null; then
    mv "$_cfg_tmp" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
else
    rm -f "$_cfg_tmp"
    _msg=$(json_esc "无法写入配置文件")
    printf '{"success":false,"message":"%s"}' "$_msg"
    exit 0
fi

export OPERATOR="$_operator"
_result=false
if do_login "$USERNAME" "$PASSWORD" "${ACCOUNT_TYPE:-student}" >/dev/null 2>&1; then
    _result=true
fi

if [ "$_result" = true ]; then
    _op_esc=$(json_esc "$_operator")
    _msg=$(json_esc "已切换到$_operator，网络已连接")
    printf '{"success":true,"message":"%s","operator":"%s"}' "$_msg" "$_op_esc"
else
    _op_esc=$(json_esc "$_operator")
    _msg=$(json_esc "运营商已切换为$_operator，认证稍后由守护进程自动完成")
    printf '{"success":true,"message":"%s","operator":"%s"}' "$_msg" "$_op_esc"
fi

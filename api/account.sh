#!/bin/sh
# ========================================
# API: 账号管理
# GET  /ruijie-cgi/account  → 读取账号信息
# POST /ruijie-cgi/account  → 保存账号信息
# ========================================

. "$(dirname "$0")/common.sh"

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

METHOD="${REQUEST_METHOD:-GET}"

if [ "$METHOD" = "POST" ]; then
    _body=$(read_post_body)

    _username=$(urldecode "$(body_get_field "username" "$_body")")
    _password=$(urldecode "$(body_get_field "password" "$_body")")
    _operator=$(urldecode "$(body_get_field "operator" "$_body")")

    if [ -z "$_username" ] || [ -z "$_password" ]; then
        printf '{"success":false,"message":"用户名和密码不能为空"}'
        exit 0
    fi

    load_config
    save_config "$_username" "$_password" "${ACCOUNT_TYPE:-student}"
    fix_config_perms

    if [ -n "$_operator" ]; then
        _cfg_tmp=$(mktemp)
        if sed "s/^OPERATOR=.*/OPERATOR=$_operator/" "$CONFIG_FILE" > "$_cfg_tmp" 2>/dev/null; then
            mv "$_cfg_tmp" "$CONFIG_FILE"
            chmod 600 "$CONFIG_FILE"
        else
            rm -f "$_cfg_tmp"
        fi
    fi

    printf '{"success":true,"message":"账号已保存"}'
else
    # GET: 读取（密码脱敏）
    load_config
    _masked=$(printf '%*s' "${#PASSWORD}" '' | tr ' ' '*')

    _un_esc=$(json_esc "${USERNAME:-}")
    _op_esc=$(json_esc "${OPERATOR:-DianXin}")
    _at_esc=$(json_esc "${ACCOUNT_TYPE:-student}")
    _pu_esc=$(json_esc "${PROXY_URL:-}")

    printf '{"username":"%s","password":"%s","operator":"%s","account_type":"%s","proxy_url":"%s"}' \
        "$_un_esc" "$_masked" "$_op_esc" "$_at_esc" "$_pu_esc"
fi

#!/bin/sh
# ========================================
# API: 系统设置
# GET  /ruijie-cgi/settings  → 读取代理设置
# POST /ruijie-cgi/settings  → 保存代理设置
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

METHOD="${REQUEST_METHOD:-GET}"

if [ "$METHOD" = "POST" ]; then
    _body=$(read_post_body)

    _proxy=$(urldecode "$(body_get_field "proxy_url" "$_body")")
    _proxy_https=$(urldecode "$(body_get_field "proxy_url_https" "$_body")")

    _cfg_tmp=$(mktemp)
    if [ -f "$CONFIG_FILE" ]; then
        sed -e "s|^PROXY_URL=.*|PROXY_URL=$_proxy|" \
            -e "s|^PROXY_URL_HTTPS=.*|PROXY_URL_HTTPS=$_proxy_https|" \
            "$CONFIG_FILE" > "$_cfg_tmp" 2>/dev/null && mv "$_cfg_tmp" "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE" 2>/dev/null
        _msg=$(json_esc "设置已保存")
        printf '{"success":true,"message":"%s"}' "$_msg"
    else
        rm -f "$_cfg_tmp"
        _msg=$(json_esc "配置文件不存在，请先配置账号")
        printf '{"success":false,"message":"%s"}' "$_msg"
    fi
else
    load_config
    _pe=$(json_esc "${PROXY_URL:-}")
    _phe=$(json_esc "${PROXY_URL_HTTPS:-}")
    printf '{"proxy_url":"%s","proxy_url_https":"%s"}' "$_pe" "$_phe"
fi

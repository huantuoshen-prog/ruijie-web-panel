#!/bin/sh
# ========================================
# API: 面板鉴权
# GET  /ruijie-cgi/auth    → 当前登录状态
# POST /ruijie-cgi/auth    → 密码登录 / 退出登录
# ========================================

. "$(dirname "$0")/../api/common.sh"

METHOD="${REQUEST_METHOD:-GET}"

if [ "$METHOD" = "GET" ]; then
    echo "Content-Type: application/json; charset=utf-8"
    echo ""
    if panel_is_authenticated; then
        printf '{"success":true,"authenticated":true}'
    else
        printf '{"success":true,"authenticated":false}'
    fi
    exit 0
fi

_body=$(read_post_body)
_action=$(body_get_field "action" "$_body")

if [ "$_action" = "logout" ]; then
    panel_destroy_session "$(panel_extract_cookie "$PANEL_SESSION_COOKIE")"
    panel_clear_session_cookie
    echo "Content-Type: application/json; charset=utf-8"
    echo ""
    printf '{"success":true,"message":"已退出登录"}'
    exit 0
fi

_password=$(urldecode "$(body_get_field "password" "$_body")")
_stored_hash="$(panel_get_auth_hash)"

echo "Content-Type: application/json; charset=utf-8"

if [ -z "$_stored_hash" ]; then
    echo ""
    printf '{"success":false,"message":"面板密码未初始化，请重新运行安装脚本"}'
    exit 0
fi

if [ -z "$_password" ]; then
    echo ""
    printf '{"success":false,"message":"请输入面板密码"}'
    exit 0
fi

_password_hash="$(panel_hash_password "$_password" 2>/dev/null || true)"
if [ -n "$_password_hash" ] && [ "$_password_hash" = "$_stored_hash" ]; then
    _token="$(panel_create_session)"
    if [ -z "$_token" ]; then
        echo ""
        printf '{"success":false,"message":"无法创建登录会话"}'
        exit 0
    fi
    panel_set_session_cookie "$_token"
    echo ""
    printf '{"success":true,"message":"登录成功"}'
else
    echo ""
    printf '{"success":false,"message":"面板密码错误"}'
fi

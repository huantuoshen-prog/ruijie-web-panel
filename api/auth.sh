#!/bin/sh
. "$(dirname "$0")/../api/common.sh"
if [ "${REQUEST_METHOD:-GET}" = GET ]; then
    if panel_is_authenticated; then
        _token="$(panel_extract_cookie)"
        panel_set_session_cookie "$_token"
        printf 'Content-Type: application/json; charset=utf-8\r\nCache-Control: no-store\r\n\r\n'
        jq -cn '{schema_version:2,success:true,authenticated:true}'
    else
        http_json 200 '{"schema_version":2,"success":true,"authenticated":false}'
    fi
    exit 0
fi
require_method POST
_body="$(read_post_body)"
_action="$(urldecode "$(body_get_field action "$_body")")"
if [ "$_action" = logout ]; then
    panel_destroy_session "$(panel_extract_cookie)"
    panel_clear_session_cookie
    printf 'Content-Type: application/json; charset=utf-8\r\nCache-Control: no-store\r\n\r\n'
    printf '{"schema_version":2,"success":true,"message":"已退出登录"}'
    exit 0
fi
rate_limited && api_error 429 RATE_LIMITED '登录尝试过多，请五分钟后重试'
_password="$(urldecode "$(body_get_field password "$_body")")"
valid_value "$_password" || api_error 400 INVALID_ARGUMENT '密码不能包含换行'
_stored="$(panel_get_auth_hash)"
[ -n "$_stored" ] || api_error 500 AUTH_UNINITIALIZED '面板密码未初始化，请重新运行安装脚本'
if [ -n "$_password" ] && [ "$(panel_hash_password "$_password")" = "$_stored" ]; then
    _token="$(panel_create_session)" || api_error 500 SESSION_UNAVAILABLE '无法安全创建登录会话'
    rate_success
    panel_set_session_cookie "$_token"
    printf 'Content-Type: application/json; charset=utf-8\r\nCache-Control: no-store\r\n\r\n'
    printf '{"schema_version":2,"success":true,"message":"登录成功"}'
else
    rate_failure
    api_error 401 INVALID_CREDENTIALS '面板密码错误'
fi

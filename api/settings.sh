#!/bin/sh
. "$(dirname "$0")/../api/common.sh"
panel_require_auth
case "${REQUEST_METHOD:-GET}" in
GET) _result="$(core_call config get)" || api_error 500 CORE_FAILURE '读取配置失败'; http_json 200 "$_result";;
POST)
    require_method POST; core_require_compatible; _body="$(read_post_body)"
    _proxy="$(urldecode "$(body_get_field proxy_url "$_body")")"; _proxy_https="$(urldecode "$(body_get_field proxy_url_https "$_body")")"; _revision="$(urldecode "$(body_get_field revision "$_body")")"
    valid_value "$_proxy" && valid_value "$_proxy_https" || api_error 400 INVALID_ARGUMENT '代理地址不能包含换行'
    _current="$(core_call config get)" || api_error 500 CORE_FAILURE '读取配置失败'
    _payload="$(jq -cn --argjson current "$_current" --arg proxy "$_proxy" --arg proxy_https "$_proxy_https" --arg revision "$_revision" '$current.data + {password:"__PRESERVE__",proxy_url:$proxy,proxy_url_https:$proxy_https,revision:$revision}')"
    _result="$(printf '%s' "$_payload" | core_call config set)"; _exit=$?
    case "$_exit" in 0) http_json 200 "$_result";; 3) http_json 409 "$_result";; *) http_json 400 "$_result";; esac
    ;;
*) api_error 400 INVALID_METHOD 'expected GET or POST';;
esac

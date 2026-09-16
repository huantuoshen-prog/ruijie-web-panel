#!/bin/sh
. "$(dirname "$0")/../api/common.sh"
panel_require_auth
case "${REQUEST_METHOD:-GET}" in
GET) _result="$(core_call health status)" || api_error 500 CORE_FAILURE '读取健康状态失败'; http_json 200 "$_result";;
POST)
 require_method POST; core_require_compatible; _body="$(read_post_body)"; _action="$(urldecode "$(body_get_field action "$_body")")"; _duration="$(urldecode "$(body_get_field duration "$_body")")"
 case "$_action" in enable) _result="$(core_call health enable "${_duration:-3d}")";; disable) _result="$(core_call health disable)";; *) api_error 400 INVALID_ARGUMENT '未知健康监听操作';; esac
 http_json 200 "$_result";;
*) api_error 400 INVALID_METHOD 'expected GET or POST';;
esac

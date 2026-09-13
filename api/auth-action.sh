#!/bin/sh
. "$(dirname "$0")/../api/common.sh"
panel_require_auth
require_method POST
core_require_compatible
_body="$(read_post_body)"
_action="$(urldecode "$(body_get_field action "$_body")")"
case "$_action" in ensure|reauth|logout) ;; *) api_error 400 INVALID_ARGUMENT '未知认证操作';; esac
_result="$(core_call auth "$_action")"; _exit=$?
case "$_exit" in
0) http_json 200 "$_result" ;;
1) http_json 502 "$_result" ;;
2) http_json 400 "$_result" ;;
3) http_json 409 "$_result" ;;
*) http_json 500 "$_result" ;;
esac

#!/bin/sh
. "$(dirname "$0")/../api/common.sh"
panel_require_auth; require_method POST
core_require_compatible
_action="$(urldecode "$(body_get_field action "$(read_post_body)")")"
case "$_action" in start|stop|restart) ;; *) api_error 400 INVALID_ARGUMENT '未知服务操作';; esac
_result="$(core_call service "$_action")"; _exit=$?
case "$_exit" in 0) http_json 200 "$_result";; 2) http_json 400 "$_result";; *) http_json 500 "$_result";; esac

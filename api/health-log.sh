#!/bin/sh
. "$(dirname "$0")/../api/common.sh"
panel_require_auth; require_method GET
_lines="$(urldecode "$(body_get_field lines "${QUERY_STRING:-}")")"
_result="$(core_call logs health "${_lines:-100}")" || api_error 500 CORE_FAILURE '读取健康日志失败'
http_json 200 "$_result"

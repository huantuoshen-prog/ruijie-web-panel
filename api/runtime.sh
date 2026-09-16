#!/bin/sh
. "$(dirname "$0")/../api/common.sh"
panel_require_auth; require_method GET
_result="$(core_call runtime)" || api_error 500 CORE_FAILURE '读取运行环境失败'
http_json 200 "$_result"

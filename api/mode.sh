#!/bin/sh
. "$(dirname "$0")/../api/common.sh"
panel_require_auth; require_method POST
api_error 400 UNSUPPORTED '运营商切换需在账号页面保存后显式应用并重新认证'

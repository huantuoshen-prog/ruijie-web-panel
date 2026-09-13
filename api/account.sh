#!/bin/sh
. "$(dirname "$0")/../api/common.sh"
panel_require_auth
case "${REQUEST_METHOD:-GET}" in
GET)
    _result="$(core_call config get)" || api_error 500 CORE_FAILURE '读取配置失败'
    http_json 200 "$_result"
    ;;
POST)
    require_method POST
    core_require_compatible
    _body="$(read_post_body)"
    _username="$(urldecode "$(body_get_field username "$_body")")"
    _password="$(urldecode "$(body_get_field password "$_body")")"
    _operator="$(urldecode "$(body_get_field operator "$_body")")"
    _revision="$(urldecode "$(body_get_field revision "$_body")")"
    valid_value "$_username" && valid_value "$_password" && valid_value "$_operator" || api_error 400 INVALID_ARGUMENT '字段不能包含换行'
    _payload="$(jq -cn --arg username "$_username" --arg password "$_password" --arg operator "$_operator" --arg revision "$_revision" '{username:$username,password:$password,operator:$operator,revision:$revision}')"
    _result="$(printf '%s' "$_payload" | core_call config set)"; _exit=$?
    case "$_exit" in 0) http_json 200 "$_result";; 3) http_json 409 "$_result";; *) http_json 400 "$_result";; esac
    ;;
*) api_error 400 INVALID_METHOD 'expected GET or POST';;
esac

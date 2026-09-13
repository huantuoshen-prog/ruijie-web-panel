#!/bin/sh
# HTTP boundary only. Core business operations run through ruijiectl.
PANEL_AUTH_DIR="${RUIJIE_PANEL_AUTH_DIR:-/etc/ruijie-panel}"
PANEL_AUTH_FILE="${RUIJIE_PANEL_AUTH_FILE:-${PANEL_AUTH_DIR}/auth.conf}"
PANEL_SESSION_DIR="${RUIJIE_PANEL_SESSION_DIR:-/tmp/ruijie-panel.sessions}"
PANEL_RATE_DIR="${RUIJIE_PANEL_RATE_DIR:-/tmp/ruijie-panel.rate}"
PANEL_SESSION_COOKIE="ruijie_panel_session"
PANEL_SESSION_MAX_AGE="${RUIJIE_PANEL_SESSION_MAX_AGE:-2592000}"
RUIJIECTL="${RUIJIECTL:-/etc/ruijie/ruijiectl}"
MAX_BODY_BYTES=16384

http_json() {
    _status="$1"; _body="$2"
    [ "$_status" = "200" ] || printf 'Status: %s\r\n' "$_status"
    printf 'Content-Type: application/json; charset=utf-8\r\nCache-Control: no-store\r\n\r\n%s' "$_body"
}
api_error() {
    _status="$1"; _code="$2"; _message="$3"
    http_json "$_status" "$(jq -cn --arg code "$_code" --arg message "$_message" '{schema_version:2,success:false,code:$code,message:$message,data:{}}')"
    exit 0
}
require_method() {
    _expected="$1"
    [ "${REQUEST_METHOD:-GET}" = "$_expected" ] || api_error 400 INVALID_METHOD "expected $_expected"
    if [ "$_expected" = POST ]; then
        case "${CONTENT_TYPE:-}" in application/x-www-form-urlencoded*|application/json*) ;; *) api_error 400 INVALID_CONTENT_TYPE 'unsupported content type';; esac
    fi
}
read_post_body() {
    _len="${CONTENT_LENGTH:-0}"
    case "$_len" in ''|*[!0-9]*) api_error 400 INVALID_BODY 'invalid content length';; esac
    [ "$_len" -le "$MAX_BODY_BYTES" ] || api_error 400 BODY_TOO_LARGE 'request body exceeds 16 KiB'
    [ "$_len" -eq 0 ] && { printf ''; return; }
    dd bs=1 count="$_len" 2>/dev/null
}
body_get_field() {
    _key="$1"; _body="$2"
    printf '%s' "$_body" | tr '&' '\n' | sed -n "s/^${_key}=//p" | head -n 1
}
urldecode() {
    _value="$(printf '%s' "$1" | sed 's/+/ /g; s/%/\\x/g')"
    printf '%b' "$_value"
}
valid_value() { printf '%s' "$1" | LC_ALL=C grep -q '[[:cntrl:]]' && return 1; return 0; }
panel_hash_password() { printf '%s' "$1" | sha256sum | awk '{print $1}'; }
panel_get_auth_hash() { [ -f "$PANEL_AUTH_FILE" ] && sed -n 's/^PASSWORD_SHA256=//p' "$PANEL_AUTH_FILE" | head -n 1; }
panel_now_epoch() { date +%s; }
panel_session_max_age() { printf '%s' "$PANEL_SESSION_MAX_AGE"; }
panel_extract_cookie() {
    printf '%s' "${HTTP_COOKIE:-}" | tr ';' '\n' | sed 's/^ *//;s/ *$//' | sed -n "s/^${PANEL_SESSION_COOKIE}=//p" | head -n1 | tr -d '\r\n'
}
panel_session_path() { case "$1" in ''|*[!0-9a-f]*) return 1;; esac; printf '%s/%s' "$PANEL_SESSION_DIR" "$1"; }
panel_session_exists() {
    _path="$(panel_session_path "$1")" || return 1
    [ -f "$_path" ] || return 1
    _expiry="$(tr -d '\r\n' < "$_path" 2>/dev/null)"
    case "$_expiry" in ''|*[!0-9]*) rm -f "$_path"; return 1;; esac
    [ "$_expiry" -gt "$(panel_now_epoch)" ] 2>/dev/null || { rm -f "$_path"; return 1; }
}
panel_new_session_token() {
    [ "${RUIJIE_PANEL_DISABLE_RANDOM:-0}" != 1 ] || return 1
    [ -r /dev/urandom ] || return 1
    if command -v od >/dev/null 2>&1; then
        dd if=/dev/urandom bs=16 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n'
    elif command -v hexdump >/dev/null 2>&1; then
        hexdump -v -n 16 -e '/1 "%02x"' /dev/urandom
    else
        return 1
    fi
}
panel_create_session() {
    mkdir -p "$PANEL_SESSION_DIR" || return 1
    chmod 700 "$PANEL_SESSION_DIR" 2>/dev/null || return 1
    umask 077
    _token="$(panel_new_session_token)" || return 1
    _tmp="$(mktemp "${PANEL_SESSION_DIR}/.tmp.XXXXXX")" || return 1
    printf '%s' "$(( $(panel_now_epoch) + $(panel_session_max_age) ))" > "$_tmp" && chmod 600 "$_tmp" && mv -f "$_tmp" "$(panel_session_path "$_token")" || { rm -f "$_tmp"; return 1; }
    printf '%s' "$_token"
}
panel_destroy_session() { _path="$(panel_session_path "$1")" || return 0; rm -f "$_path"; }
panel_set_session_cookie() { printf 'Set-Cookie: %s=%s; Path=/; Max-Age=%s; HttpOnly; SameSite=Strict\r\n' "$PANEL_SESSION_COOKIE" "$1" "$(panel_session_max_age)"; }
panel_clear_session_cookie() { printf 'Set-Cookie: %s=deleted; Path=/; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly; SameSite=Strict\r\n' "$PANEL_SESSION_COOKIE"; }
panel_is_authenticated() { _token="$(panel_extract_cookie)"; [ -n "$_token" ] && panel_session_exists "$_token"; }

rate_file() { printf '%s/%s' "$PANEL_RATE_DIR" "$(printf '%s' "${REMOTE_ADDR:-local}" | tr -cd '0-9A-Fa-f:.')"; }
rate_limited() {
    mkdir -p "$PANEL_RATE_DIR" || return 0
    chmod 700 "$PANEL_RATE_DIR" 2>/dev/null || return 0
    _file="$(rate_file)"; _now="$(panel_now_epoch)"; _state="$(cat "$_file" 2>/dev/null || true)"
    set -- $_state; _until="${3:-0}"
    [ "$_until" -gt "$_now" ] 2>/dev/null
}
rate_failure() {
    mkdir -p "$PANEL_RATE_DIR" || return
    _file="$(rate_file)"; _now="$(panel_now_epoch)"; _state="$(cat "$_file" 2>/dev/null || true)"; set -- $_state
    _count="${1:-0}"; _started="${2:-$_now}"; _until="${3:-0}"
    [ $((_now - _started)) -le 60 ] 2>/dev/null || { _count=0; _started="$_now"; }
    _count=$((_count + 1)); [ "$_count" -ge 5 ] && _until=$((_now + 300))
    umask 077; printf '%s %s %s' "$_count" "$_started" "$_until" > "$_file"
}
rate_success() { rm -f "$(rate_file)"; }
panel_require_auth() { panel_is_authenticated || api_error 401 UNAUTHENTICATED '请先登录 Web 面板'; }
core_call() { [ -x "$RUIJIECTL" ] || api_error 500 CORE_UNAVAILABLE '未找到锐捷核心'; "$RUIJIECTL" "$@"; }
core_require_compatible() {
    _runtime="$(core_call runtime)" || api_error 500 CORE_UNAVAILABLE '无法读取锐捷核心版本'
    printf '%s' "$_runtime" | jq -e '.schema_version == 2 and .success == true' >/dev/null 2>&1 \
        || api_error 409 CORE_INCOMPATIBLE '需要锐捷核心 4.0.0（接口 schema 2）才能修改配置或服务'
}

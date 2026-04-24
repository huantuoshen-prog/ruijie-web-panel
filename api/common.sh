#!/bin/sh
# ========================================
# API 共享工具库
# 被所有 CGI 脚本 source
# ========================================

# ----------------------------------------
# 1. 查找 ruijie 脚本安装路径
# ----------------------------------------
find_ruijie_dir() {
    if [ -n "${RUIJIE_DIR:-}" ] && [ -f "${RUIJIE_DIR}/ruijie.sh" ]; then
        echo "${RUIJIE_DIR}"
    elif [ -f /etc/ruijie/ruijie.sh ]; then
        echo "/etc/ruijie"
    elif [ -f /root/ruijie/ruijie.sh ]; then
        echo "/root/ruijie"
    else
        return 1
    fi
}

# ----------------------------------------
# 2. JSON / XSS 安全转义
# ----------------------------------------
json_esc() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/</\\u003c/g; s/>/\\u003e/g'
}

json_bool() {
    case "$1" in
        true|1|yes) printf 'true' ;;
        *) printf 'false' ;;
    esac
}

json_num_or_null() {
    case "$1" in
        ''|*[!0-9-]*) printf 'null' ;;
        *) printf '%s' "$1" ;;
    esac
}

PANEL_AUTH_DIR="${RUIJIE_PANEL_AUTH_DIR:-/etc/ruijie-panel}"
PANEL_AUTH_FILE="${RUIJIE_PANEL_AUTH_FILE:-${PANEL_AUTH_DIR}/auth.conf}"
PANEL_SESSION_DIR="${RUIJIE_PANEL_SESSION_DIR:-/tmp/ruijie-panel.sessions}"
PANEL_SESSION_COOKIE="ruijie_panel_session"
PANEL_LOGFILE="${RUIJIE_PANEL_LOGFILE:-${LOGFILE:-/var/log/ruijie-daemon.log}}"

panel_hash_password() {
    _password="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        printf '%s' "$_password" | sha256sum | awk '{print $1}'
    elif command -v openssl >/dev/null 2>&1; then
        printf '%s' "$_password" | openssl dgst -sha256 | awk '{print $NF}'
    else
        return 1
    fi
}

panel_get_auth_hash() {
    if [ -f "$PANEL_AUTH_FILE" ]; then
        grep '^PASSWORD_SHA256=' "$PANEL_AUTH_FILE" 2>/dev/null | cut -d= -f2-
    fi
}

panel_extract_cookie() {
    _cookie_name="$1"
    printf '%s' "${HTTP_COOKIE:-}" | tr ';' '\n' | sed 's/^ *//;s/ *$//' \
        | sed -n "s/^${_cookie_name}=//p" | head -n 1 | tr -d '\r\n'
}

panel_session_path() {
    _token="$1"
    case "$_token" in
        ''|*[!0-9a-f]*)
            return 1
            ;;
    esac
    printf '%s/%s' "$PANEL_SESSION_DIR" "$_token"
}

panel_session_exists() {
    _path="$(panel_session_path "$1")" || return 1
    [ -f "$_path" ]
}

panel_create_session() {
    mkdir -p "$PANEL_SESSION_DIR" || return 1
    _token="$(panel_new_session_token)" || return 1
    _path="$(panel_session_path "$_token")" || return 1
    : > "$_path" || return 1
    chmod 600 "$_path" 2>/dev/null || true
    printf '%s' "$_token"
}

panel_destroy_session() {
    _path="$(panel_session_path "$1")" || return 0
    rm -f "$_path" 2>/dev/null
}

panel_is_authenticated() {
    _cookie_token="$(panel_extract_cookie "$PANEL_SESSION_COOKIE")"
    [ -n "$_cookie_token" ] && panel_session_exists "$_cookie_token"
}

panel_new_session_token() {
    if command -v od >/dev/null 2>&1; then
        dd if=/dev/urandom bs=16 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n'
    else
        date '+%s%N'
    fi
}

panel_set_session_cookie() {
    _token="$1"
    printf 'Set-Cookie: %s=%s; Path=/; HttpOnly; SameSite=Strict\r\n' "$PANEL_SESSION_COOKIE" "$_token"
}

panel_clear_session_cookie() {
    printf 'Set-Cookie: %s=deleted; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly; SameSite=Strict\r\n' "$PANEL_SESSION_COOKIE"
}

panel_require_auth() {
    if panel_is_authenticated; then
        return 0
    fi

    echo "Status: 401 Unauthorized"
    echo "Content-Type: application/json; charset=utf-8"
    echo ""
    printf '{"success":false,"message":"请先登录 Web 面板"}'
    return 1
}

# ----------------------------------------
# 3. 纯 shell URL 解码（兼容 OpenWrt）
# ----------------------------------------
urldecode() {
    printf '%s' "$1" | sed '
        s/%20/ /g; s/%21/!/g; s/%23/#/g; s/%24/$/g
        s/%26/\&/g; s/%27/'"'"'/g; s/%28/(/g; s/%29/)/g
        s/%2B/+/g; s/%2C/,/g; s/%2F/\//g; s/%3A/:/g
        s/%3B/;/g; s/%3D/=/g; s/%3F/?/g; s/%40/@/g
        s/%5B/[/g; s/%5D/]/g
        s/%0A//g; s/%0D//g
    '
}

# ----------------------------------------
# 4. 读取 POST body（application/x-www-form-urlencoded）
# ----------------------------------------
read_post_body() {
    _len="${CONTENT_LENGTH:-0}"
    _body=""
    [ "$_len" -gt 0 ] 2>/dev/null && read -n "$_len" _body 2>/dev/null || true
    printf '%s' "$_body"
}

# ----------------------------------------
# 5. 从 body 中提取字段（urlencoded）
# ----------------------------------------
# 用法: body_get_field "username" "$_body"
body_get_field() {
    _key="$1"
    _body="$2"
    echo "$_body" | sed -n 's/.*'"$_key"'=\([^&]*\).*/\1/p'
}

query_get_field() {
    _key="$1"
    echo "${QUERY_STRING:-}" | sed -n 's/.*'"$_key"'=\([^&]*\).*/\1/p'
}

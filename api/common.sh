#!/bin/sh
# ========================================
# API 共享工具库
# 被所有 CGI 脚本 source
# ========================================

# ----------------------------------------
# 1. 查找 ruijie 脚本安装路径
# ----------------------------------------
find_ruijie_dir() {
    if [ -f /etc/ruijie/ruijie.sh ]; then
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

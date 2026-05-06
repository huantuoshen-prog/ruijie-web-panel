#!/bin/bash
# ========================================
# 单元测试: 面板登录会话持久化
# 用法: bash tests/test_session_persistence.sh
# ========================================

set -e

PROJECT_DIR="$(cd "$(dirname "${0}")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

pass() { echo "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }

TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

PANEL_SESSION_DIR="${TMPDIR}/sessions"
RUIJIE_PANEL_SESSION_MAX_AGE=2592000

. "${PROJECT_DIR}/api/common.sh"

panel_new_session_token() {
    printf '%s' 'abc123'
}

echo "========== 面板会话持久化测试 =========="

cookie_header="$(panel_set_session_cookie "abc123")"
echo "$cookie_header" | grep -q 'Max-Age=2592000' \
    && pass "登录 Cookie 包含持久化 Max-Age" \
    || fail "登录 Cookie 未包含持久化 Max-Age"
if echo "$cookie_header" | grep -q 'Path=/'; then
    pass "登录 Cookie 保留根路径"
else
    fail "登录 Cookie 丢失根路径"
fi

token="$(panel_create_session)"
[ "$token" = "abc123" ] \
    && pass "创建会话时返回预期 token" \
    || fail "创建会话时 token 异常: ${token:-<empty>}"

session_file="${PANEL_SESSION_DIR}/abc123"
[ -f "$session_file" ] \
    && pass "创建会话后写入 session 文件" \
    || fail "创建会话后未写入 session 文件"

expiry_value="$(cat "$session_file" 2>/dev/null)"
case "$expiry_value" in
    ''|*[!0-9]*)
        fail "session 文件未写入合法过期时间: ${expiry_value:-<empty>}"
        ;;
    *)
        pass "session 文件写入合法过期时间"
        ;;
esac

if panel_session_exists "abc123"; then
    pass "未过期 session 仍被识别为有效"
else
    fail "未过期 session 未被识别为有效"
fi

printf '1' > "$session_file"
if panel_session_exists "abc123"; then
    fail "已过期 session 仍被识别为有效"
else
    pass "已过期 session 会被拒绝"
fi

[ ! -f "$session_file" ] \
    && pass "过期 session 会被清理" \
    || fail "过期 session 未被清理"

logout_cookie="$(panel_clear_session_cookie)"
echo "$logout_cookie" | grep -q 'Max-Age=0' \
    && pass "退出登录时清除 Cookie 的 Max-Age"
if echo "$logout_cookie" | grep -q 'Expires=Thu, 01 Jan 1970'; then
    pass "退出登录时写入过期时间"
else
    fail "退出登录时未写入过期时间"
fi

echo ""
echo "=========================================="
echo "  结果: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "=========================================="

[ "$FAIL" -gt 0 ] && exit 1 || exit 0

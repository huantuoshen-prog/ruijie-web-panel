#!/bin/bash
# ========================================
# 单元测试: api/common.sh 安全辅助函数
# 用法: bash tests/test_common_security.sh
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
. "${PROJECT_DIR}/api/common.sh"

echo "========== common.sh 安全辅助函数测试 =========="

value="$(body_get_field "username" "xusername=bad&username=good&password=secret")"
[ "$value" = "good" ] \
    && pass "body_get_field 不匹配带前缀的字段名" \
    || fail "body_get_field 字段名前缀处理错误: ${value:-<empty>}"

value="$(body_get_field "username" "username=first&username=second")"
[ "$value" = "first" ] \
    && pass "body_get_field 重复字段取第一个值" \
    || fail "body_get_field 重复字段处理错误: ${value:-<empty>}"

value="$(body_get_field "password" "username=good&password=a%3Db%26c")"
[ "$value" = "a%3Db%26c" ] \
    && pass "body_get_field 保留 urlencoded 值供调用方解码" \
    || fail "body_get_field urlencoded 值处理错误: ${value:-<empty>}"

# 强制跳过 od 分支，覆盖 fallback token 生成逻辑。
token="$(RUIJIE_PANEL_DISABLE_OD=1 panel_new_session_token 2>/dev/null || true)"
case "$token" in
    [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*)
        pass "panel_new_session_token 无 od 时仍生成哈希 token"
        ;;
    *)
        fail "panel_new_session_token 无 od 时 token 异常: ${token:-<empty>}"
        ;;
esac

case "$token" in
    ''|*[!0-9]*)
        pass "panel_new_session_token fallback 不再是纯时间戳"
        ;;
    *)
        fail "panel_new_session_token fallback 仍是纯数字: $token"
        ;;
esac

echo ""
echo "=========================================="
echo "  结果: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "=========================================="

[ "$FAIL" -gt 0 ] && exit 1 || exit 0

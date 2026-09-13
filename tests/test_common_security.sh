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

token="$(panel_new_session_token 2>/dev/null || true)"
printf '%s' "$token" | grep -qE '^[0-9a-f]{32}$' \
    && pass "panel_new_session_token 生成 128 位随机 token" \
    || fail "panel_new_session_token 未生成有效 token"

# 安全随机源不可用时必须拒绝创建会话，不能退回到时间戳 token。
token="$(RUIJIE_PANEL_DISABLE_RANDOM=1 panel_new_session_token 2>/dev/null || true)"
case "$token" in
    '')
        pass "panel_new_session_token 无安全随机源时拒绝创建 token"
        ;;
    *)
        fail "panel_new_session_token 在禁用安全随机源后仍返回 token: $token"
        ;;
esac

echo ""
echo "=========================================="
echo "  结果: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "=========================================="

[ "$FAIL" -gt 0 ] && exit 1 || exit 0

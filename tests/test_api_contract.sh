#!/bin/bash
# ========================================
# 集成测试: Web Panel CGI/API 合同
# 用法: bash tests/test_api_contract.sh
# ========================================

set -e

PROJECT_DIR="$(cd "$(dirname "${0}")/.." && pwd)"
MAIN_REPO_DIR="${PROJECT_DIR}/../ruijie-gdstvc-autologin"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

pass() { echo "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }

if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
elif command -v py.exe >/dev/null 2>&1; then
    PYTHON_BIN="py.exe -3"
else
    PYTHON_BIN=""
fi

TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

export HOME="${TMPDIR}/home"
mkdir -p "${HOME}/.config/ruijie" "${TMPDIR}/panel-auth" "${TMPDIR}/webroot/api" "${TMPDIR}/webroot/ruijie-cgi"

CONFIG_FILE="${HOME}/.config/ruijie/ruijie.conf"
cat > "$CONFIG_FILE" <<'EOF'
USERNAME=teacher01
PASSWORD=secret-pass
ACCOUNT_TYPE=teacher
OPERATOR=DianXin
DAEMON_INTERVAL=300
PROXY_URL=
PROXY_URL_HTTPS=
NO_PROXY_LIST=www.google.cn
EOF

cat > "${TMPDIR}/log.txt" <<'EOF'
[2026-04-21 12:00:00] [INFO] 守护进程已启动
[2026-04-21 12:00:01] [OK] 认证成功
EOF

printf 'PASSWORD_SHA256=%s\n' "$(printf 'panel-secret' | sha256sum | awk '{print $1}')" \
    > "${TMPDIR}/panel-auth/auth.conf"

cp "${PROJECT_DIR}/api/"*.sh "${TMPDIR}/webroot/api/"
for name in auth account daemon log mode settings status; do
    cp "${PROJECT_DIR}/api/${name}.sh" "${TMPDIR}/webroot/ruijie-cgi/${name}"
done
chmod +x "${TMPDIR}/webroot/api/"*.sh "${TMPDIR}/webroot/ruijie-cgi/"*

run_cgi() {
    local script_name="$1"
    local method="$2"
    local body="${3:-}"
    local cookie="${4:-}"

    local content_length
    content_length="$(printf '%s' "$body" | wc -c | tr -d ' ')"

    printf '%s' "$body" | env \
        HOME="$HOME" \
        REQUEST_METHOD="$method" \
        CONTENT_LENGTH="$content_length" \
        HTTP_COOKIE="$cookie" \
        RUIJIE_DIR="$MAIN_REPO_DIR" \
        RUIJIE_PANEL_AUTH_DIR="${TMPDIR}/panel-auth" \
        RUIJIE_PANEL_SESSION_DIR="${TMPDIR}/panel-sessions" \
        RUIJIE_PANEL_LOGFILE="${TMPDIR}/log.txt" \
        bash "${TMPDIR}/webroot/ruijie-cgi/${script_name}"
}

response_body() {
    printf '%s' "$1" | awk '{
        sub(/\r$/, "", $0)
        if (body) {
            print
        } else if ($0 == "") {
            body = 1
        }
    }'
}

echo "========== Web Panel API 合同测试 =========="

unauth_status="$(run_cgi status GET)"
echo "$unauth_status" | grep -q '"success":false' \
    && pass "未登录时 status 接口拒绝访问" \
    || fail "未登录时 status 接口未拒绝访问"

auth_login="$(run_cgi auth POST 'password=panel-secret')"
if echo "$auth_login" | grep -q 'Set-Cookie:'; then
    pass "登录接口返回会话 Cookie"
else
    fail "登录接口未返回会话 Cookie"
fi

session_cookie="$(echo "$auth_login" | sed -n 's/^Set-Cookie: \([^;]*\).*/\1/p' | head -n 1)"
if echo "$auth_login" | grep -q '"success":true'; then
    pass "登录接口返回成功 JSON"
else
    fail "登录接口未返回成功 JSON"
fi

second_login="$(run_cgi auth POST 'password=panel-secret')"
second_cookie="$(echo "$second_login" | sed -n 's/^Set-Cookie: \([^;]*\).*/\1/p' | head -n 1)"
second_status="$(run_cgi status GET '' "$second_cookie")"
echo "$second_status" | grep -q '"installed":true' \
    && pass "第二个会话登录后可以访问状态接口" \
    || fail "第二个会话登录后无法访问状态接口"

first_status_after_second_login="$(run_cgi status GET '' "$session_cookie")"
echo "$first_status_after_second_login" | grep -q '"installed":true' \
    && pass "第二个会话登录后，第一个会话仍然有效" \
    || fail "第二个会话登录后，第一个会话被意外踢下线"

logout_second="$(run_cgi auth POST 'action=logout' "$second_cookie")"
echo "$logout_second" | grep -q '"success":true' \
    && pass "退出登录接口返回成功" \
    || fail "退出登录接口未返回成功"

first_status_after_second_logout="$(run_cgi status GET '' "$session_cookie")"
echo "$first_status_after_second_logout" | grep -q '"installed":true' \
    && pass "第二个会话退出后，第一个会话仍然有效" \
    || fail "第二个会话退出后，第一个会话也被一并登出"

second_status_after_logout="$(run_cgi status GET '' "$second_cookie")"
echo "$second_status_after_logout" | grep -q '"success":false' \
    && pass "退出后，已登出的会话无法继续访问" \
    || fail "退出后，已登出的会话仍可继续访问"

account_save="$(run_cgi account POST 'username=teacher02&password=next-pass&operator=LianTong' "$session_cookie")"
echo "$account_save" | grep -q '"success":true' \
    && pass "账号保存接口返回成功" \
    || fail "账号保存接口未返回成功"
grep -q '^ACCOUNT_TYPE=teacher$' "$CONFIG_FILE" \
    && pass "账号保存后保留 teacher 账号类型" \
    || fail "账号保存后丢失 teacher 账号类型"

log_payload="$(run_cgi log GET '' "$session_cookie")"
log_body="$(response_body "$log_payload")"
printf '%s' "$log_body" | grep -q '"total":2' \
    && pass "日志接口 total 与返回行数一致" \
    || fail "日志接口 total 不正确"
if [ -n "$PYTHON_BIN" ] && printf '%s' "$log_body" | eval "$PYTHON_BIN -c 'import json,sys; json.load(sys.stdin)'" >/dev/null 2>&1; then
    pass "日志接口返回合法 JSON"
else
    fail "日志接口返回非法 JSON"
fi

echo ""
echo "=========================================="
echo "  结果: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "=========================================="

[ "$FAIL" -gt 0 ] && exit 1 || exit 0

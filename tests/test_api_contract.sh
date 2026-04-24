#!/bin/bash
# ========================================
# 集成测试: Web Panel CGI/API 合同
# 用法: bash tests/test_api_contract.sh
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

FAKE_RUIJIE_DIR="${TMPDIR}/fake-ruijie"
mkdir -p "${FAKE_RUIJIE_DIR}/lib"

CONFIG_FILE="${HOME}/.config/ruijie/ruijie.conf"
HEALTH_CONFIG_FILE="${HOME}/.config/ruijie/health-monitor.conf"
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

cat > "$HEALTH_CONFIG_FILE" <<'EOF'
HEALTH_MONITOR_ENABLED=true
HEALTH_MONITOR_MODE=timed
HEALTH_MONITOR_UNTIL=1999999999
HEALTH_MONITOR_BASELINE_INTERVAL=900
HEALTH_MONITOR_REDACTION=mask_password_and_session_only
HEALTH_MONITOR_CREATED_AT=1900000000
EOF

cat > "${TMPDIR}/log.txt" <<'EOF'
[2026-04-21 12:00:00] [INFO] 守护进程已启动
[2026-04-21 12:00:01] [OK] 认证成功
EOF

cat > "${TMPDIR}/health.log" <<'EOF'
{"ts":"2026-04-21 12:00:00","level":"WARN","type":"network_error","message":"在线检测失败"}
{"ts":"2026-04-21 12:00:01","level":"ERROR","type":"auth_failed","message":"认证失败"}
EOF

printf 'PASSWORD_SHA256=%s\n' "$(printf 'panel-secret' | sha256sum | awk '{print $1}')" \
    > "${TMPDIR}/panel-auth/auth.conf"

cat > "${FAKE_RUIJIE_DIR}/ruijie.sh" <<'EOF'
#!/bin/sh
exit 0
EOF

cat > "${FAKE_RUIJIE_DIR}/lib/common.sh" <<'EOF'
#!/bin/sh
RUIJIE_VERSION="3.1"
CONFIG_DIR="${HOME}/.config/ruijie"
CONFIG_FILE="${CONFIG_DIR}/ruijie.conf"
PIDFILE="${TMPDIR:-/tmp}/ruijie-daemon.pid"
LOGFILE="${TMPDIR:-/tmp}/ruijie-daemon.log"
EOF

cat > "${FAKE_RUIJIE_DIR}/lib/config.sh" <<'EOF'
#!/bin/sh
load_config() {
    [ -f "$CONFIG_FILE" ] || return 1
    while IFS='=' read -r key value; do
        case "$key" in
            USERNAME|PASSWORD|ACCOUNT_TYPE|OPERATOR|DAEMON_INTERVAL|PROXY_URL|PROXY_URL_HTTPS|NO_PROXY_LIST)
                eval "$key=\"\$value\""
                ;;
        esac
    done < "$CONFIG_FILE"
}

save_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<CONFIG
USERNAME=$1
PASSWORD=$2
ACCOUNT_TYPE=$3
OPERATOR=${OPERATOR:-DianXin}
DAEMON_INTERVAL=${DAEMON_INTERVAL:-300}
PROXY_URL=${PROXY_URL:-}
PROXY_URL_HTTPS=${PROXY_URL_HTTPS:-}
NO_PROXY_LIST=${NO_PROXY_LIST:-www.google.cn}
CONFIG
}

fix_config_perms() {
    chmod 600 "$CONFIG_FILE" 2>/dev/null || true
}

get_last_auth_time() {
    printf '%s' '2026-04-21 12:00:01'
}
EOF

cat > "${FAKE_RUIJIE_DIR}/lib/daemon.sh" <<'EOF'
#!/bin/sh
daemon_is_running() {
    return 1
}
EOF

cat > "${FAKE_RUIJIE_DIR}/lib/network.sh" <<'EOF'
#!/bin/sh
check_network() {
    return 0
}
EOF

cat > "${FAKE_RUIJIE_DIR}/lib/health.sh" <<'EOF'
#!/bin/sh
health_apply_defaults() {
    HEALTH_CONFIG_FILE="${HEALTH_CONFIG_FILE:-${HOME}/.config/ruijie/health-monitor.conf}"
    HEALTH_LOGFILE="${HEALTH_LOGFILE:-/tmp/ruijie-health.log}"
    HEALTH_STATUS_FILE="${HEALTH_STATUS_FILE:-/tmp/ruijie-health.status.json}"
    RUNTIME_STATUS_FILE="${RUNTIME_STATUS_FILE:-/tmp/ruijie-runtime.status.json}"
}

health_load_config() {
    health_apply_defaults
    HEALTH_MONITOR_ENABLED=false
    HEALTH_MONITOR_MODE=timed
    HEALTH_MONITOR_UNTIL=
    HEALTH_MONITOR_BASELINE_INTERVAL=900
    HEALTH_MONITOR_REDACTION=mask_password_and_session_only
    HEALTH_MONITOR_CREATED_AT=
    [ -f "$HEALTH_CONFIG_FILE" ] || return 0
    while IFS='=' read -r key value; do
        case "$key" in
            HEALTH_MONITOR_ENABLED|HEALTH_MONITOR_MODE|HEALTH_MONITOR_UNTIL|HEALTH_MONITOR_BASELINE_INTERVAL|HEALTH_MONITOR_REDACTION|HEALTH_MONITOR_CREATED_AT)
                eval "$key=\"\$value\""
                ;;
        esac
    done < "$HEALTH_CONFIG_FILE"
}

health_save_config() {
    health_apply_defaults
    cat > "$HEALTH_CONFIG_FILE" <<CONFIG
HEALTH_MONITOR_ENABLED=${HEALTH_MONITOR_ENABLED:-false}
HEALTH_MONITOR_MODE=${HEALTH_MONITOR_MODE:-timed}
HEALTH_MONITOR_UNTIL=${HEALTH_MONITOR_UNTIL:-}
HEALTH_MONITOR_BASELINE_INTERVAL=${HEALTH_MONITOR_BASELINE_INTERVAL:-900}
HEALTH_MONITOR_REDACTION=${HEALTH_MONITOR_REDACTION:-mask_password_and_session_only}
HEALTH_MONITOR_CREATED_AT=${HEALTH_MONITOR_CREATED_AT:-1900000000}
CONFIG
}

health_enable() {
    health_apply_defaults
    HEALTH_MONITOR_ENABLED=true
    HEALTH_MONITOR_MODE=timed
    HEALTH_MONITOR_UNTIL=2999999999
    HEALTH_MONITOR_BASELINE_INTERVAL=900
    HEALTH_MONITOR_REDACTION=mask_password_and_session_only
    HEALTH_MONITOR_CREATED_AT=1900000000
    health_save_config
}

health_disable() {
    health_apply_defaults
    health_load_config
    HEALTH_MONITOR_ENABLED=false
    HEALTH_MONITOR_UNTIL=
    health_save_config
}

health_remaining_seconds() {
    echo 12345
}

health_runtime_json() {
    printf '{"platform":"openwrt","kernel":"5.10.0","arch":"aarch64","shell":"sh","busybox_present":true,"curl_present":true,"nohup_backend":"nohup","script_dir":"%s","config_file":"%s","daemon_pidfile":"%s","daemon_logfile":"%s","health_logfile":"%s","panel_installed":true,"panel_web_root":"/www/ruijie-panel","daemon_running":false,"health_collector_active":false}' "$RUIJIE_DIR" "$CONFIG_FILE" "$PIDFILE" "$LOGFILE" "$HEALTH_LOGFILE"
}

health_snapshot_json() {
    printf '{"online":true,"daemon_running":false,"daemon_state":"","daemon_pid":"","username":"%s","account_type":"%s","operator":"%s"}' "$USERNAME" "$ACCOUNT_TYPE" "$OPERATOR"
}

health_write_runtime_snapshot() {
    health_apply_defaults
    health_runtime_json > "$RUNTIME_STATUS_FILE"
}

health_write_status_snapshot() {
    health_apply_defaults
    health_load_config
    printf '{"supported":true,"enabled":%s,"mode":"%s","until":"%s","remaining_seconds":12345,"collector_active":false,"baseline_interval":900,"redaction":"%s","last_event_at":"2026-04-21 12:00:01","snapshot":%s}' "$HEALTH_MONITOR_ENABLED" "$HEALTH_MONITOR_MODE" "$HEALTH_MONITOR_UNTIL" "$HEALTH_MONITOR_REDACTION" "$(health_snapshot_json)" > "$HEALTH_STATUS_FILE"
}

health_log_json() {
    health_apply_defaults
    _type="${3:-}"
    _lines="$(cat "$HEALTH_LOGFILE")"
    if [ -n "$_type" ]; then
        _lines="$(printf '%s\n' "$_lines" | grep "\"type\":\"$_type\"")"
    fi
    _count="$(printf '%s\n' "$_lines" | grep -c '"ts"' || true)"
    printf '{"success":true,"entries":[%s],"total":%s}' "$(printf '%s\n' "$_lines" | paste -sd, -)" "$_count"
}
EOF

chmod +x "${FAKE_RUIJIE_DIR}/ruijie.sh" "${FAKE_RUIJIE_DIR}/lib/"*.sh

cp "${PROJECT_DIR}/api/"*.sh "${TMPDIR}/webroot/api/"
for name in auth account daemon health health-log log mode runtime settings status; do
    cp "${PROJECT_DIR}/api/${name}.sh" "${TMPDIR}/webroot/ruijie-cgi/${name}"
done
chmod +x "${TMPDIR}/webroot/api/"*.sh "${TMPDIR}/webroot/ruijie-cgi/"*

run_cgi() {
    local script_name="$1"
    local method="$2"
    local body="${3:-}"
    local cookie="${4:-}"
    local query_string=""

    if [ "$method" = "GET" ]; then
        query_string="$body"
        body=""
    fi

    local content_length
    content_length="$(printf '%s' "$body" | wc -c | tr -d ' ')"

    printf '%s' "$body" | env \
        HOME="$HOME" \
        REQUEST_METHOD="$method" \
        QUERY_STRING="$query_string" \
        CONTENT_LENGTH="$content_length" \
        HTTP_COOKIE="$cookie" \
        RUIJIE_DIR="$FAKE_RUIJIE_DIR" \
        RUIJIE_PANEL_AUTH_DIR="${TMPDIR}/panel-auth" \
        RUIJIE_PANEL_SESSION_DIR="${TMPDIR}/panel-sessions" \
        RUIJIE_PANEL_LOGFILE="${TMPDIR}/log.txt" \
        HEALTH_CONFIG_FILE="${HEALTH_CONFIG_FILE}" \
        HEALTH_LOGFILE="${TMPDIR}/health.log" \
        HEALTH_STATUS_FILE="${TMPDIR}/health.status.json" \
        RUNTIME_STATUS_FILE="${TMPDIR}/runtime.status.json" \
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

response_header_value() {
    printf '%s' "$1" | awk -v header="$2" '{
        sub(/\r$/, "", $0)
        if ($0 ~ ("^" header ": ")) {
            sub("^" header ": ", "", $0)
            print
            exit
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

session_cookie="$(response_header_value "$auth_login" "Set-Cookie" | sed 's/;.*//')"
if echo "$auth_login" | grep -q '"success":true'; then
    pass "登录接口返回成功 JSON"
else
    fail "登录接口未返回成功 JSON"
fi

second_login="$(run_cgi auth POST 'password=panel-secret')"
second_cookie="$(response_header_value "$second_login" "Set-Cookie" | sed 's/;.*//')"
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

health_payload="$(run_cgi health GET '' "$session_cookie")"
echo "$health_payload" | grep -q '"enabled":true' \
    && pass "健康状态接口返回 enabled=true" \
    || fail "健康状态接口未返回 enabled=true"

health_enable_payload="$(run_cgi health POST 'action=enable&duration=7d' "$session_cookie")"
echo "$health_enable_payload" | grep -q '"enabled":true' \
    && pass "健康状态接口支持启用监听" \
    || fail "健康状态接口未成功启用监听"

health_log_payload="$(run_cgi health-log GET 'type=auth_failed' "$session_cookie")"
health_log_body="$(response_body "$health_log_payload")"
printf '%s' "$health_log_body" | grep -q '"total":1' \
    && pass "健康日志接口支持按类型筛选" \
    || fail "健康日志接口未正确按类型筛选"

runtime_payload="$(run_cgi runtime GET '' "$session_cookie")"
echo "$runtime_payload" | grep -q '"platform":"openwrt"' \
    && pass "运行环境接口返回平台信息" \
    || fail "运行环境接口未返回平台信息"

echo ""
echo "=========================================="
echo "  结果: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "=========================================="

[ "$FAIL" -gt 0 ] && exit 1 || exit 0

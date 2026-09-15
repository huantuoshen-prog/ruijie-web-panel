#!/bin/bash
# API contract against the actual pinned core interface. No network auth/service
# operation is performed; all configuration and sessions stay in a temp folder.
set -euE
trap 'printf "API contract test failed at line %s\n" "$LINENO" >&2' ERR
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
: "${RUIJIECTL:?Set RUIJIECTL to a real checked-out ruijiectl executable}"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export CONFIG_DIR="$scratch/config"
export CONFIG_FILE="$scratch/config/account.conf"
export RUIJIE_CONFIG_HOME="$scratch/config"
export RUIJIE_PANEL_AUTH_DIR="$scratch/auth"
export RUIJIE_PANEL_SESSION_DIR="$scratch/sessions"
export RUIJIE_PANEL_RATE_DIR="$scratch/rate"
mkdir -p "$RUIJIE_PANEL_AUTH_DIR"
printf 'PASSWORD_SHA256=%s\n' "$(printf '%s' panel-secret | sha256sum | cut -d' ' -f1)" > "$RUIJIE_PANEL_AUTH_DIR/auth.conf"

core_payload='{"revision":"0","username":"teacher01","password":"secret-pass","account_type":"teacher","operator":"default","proxy_url":"http://127.0.0.1:7890","proxy_url_https":""}'
printf '%s' "$core_payload" | "$RUIJIECTL" config set | jq -e '.success' >/dev/null

run_cgi() {
    local script="$1" method="$2" body="${3:-}" cookie="${4:-}"
    printf '%s' "$body" | env \
        REQUEST_METHOD="$method" CONTENT_TYPE='application/x-www-form-urlencoded' \
        CONTENT_LENGTH="${#body}" HTTP_COOKIE="$cookie" REMOTE_ADDR=127.0.0.1 \
        RUIJIECTL="$RUIJIECTL" RUIJIE_CONFIG_HOME="$RUIJIE_CONFIG_HOME" \
        CONFIG_DIR="$CONFIG_DIR" CONFIG_FILE="$CONFIG_FILE" \
        RUIJIE_PANEL_AUTH_DIR="$RUIJIE_PANEL_AUTH_DIR" \
        RUIJIE_PANEL_SESSION_DIR="$RUIJIE_PANEL_SESSION_DIR" \
        RUIJIE_PANEL_RATE_DIR="$RUIJIE_PANEL_RATE_DIR" \
        sh "$ROOT/api/$script.sh"
}
body() { awk '{ sub(/\r$/, ""); if (seen) print; else if ($0 == "") seen=1; }'; }
header() { awk -v wanted="$2" '{ sub(/\r$/, ""); if ($0 ~ ("^" wanted ": ")) { sub("^" wanted ": ", ""); print; exit } }' <<<"$1"; }

unauthorized="$(run_cgi account.sh GET)"
[[ "$unauthorized" == *'401 Unauthorized'* ]]
printf '%s' "$unauthorized" | body | jq -e '.code == "UNAUTHENTICATED"' >/dev/null

login_one="$(run_cgi auth.sh POST 'password=panel-secret')"
cookie_one="$(header "$login_one" Set-Cookie | sed 's/;.*//')"
[[ "$cookie_one" == ruijie_panel_session=* ]]
[[ "$login_one" == *'Max-Age=2592000'* ]]
printf '%s' "$login_one" | body | jq -e '.success' >/dev/null

auth_state="$(run_cgi auth.sh GET '' "$cookie_one")"
printf '%s' "$auth_state" | body | jq -e '.authenticated == true' >/dev/null
[[ "$auth_state" == *'Set-Cookie:'* ]]

login_two="$(run_cgi auth.sh POST 'password=panel-secret')"
cookie_two="$(header "$login_two" Set-Cookie | sed 's/;.*//')"
account_before="$(run_cgi account.sh GET '' "$cookie_one" | body)"
revision="$(printf '%s' "$account_before" | jq -er '.data.revision')"
update="$(run_cgi account.sh POST "username=teacher02&password=next-pass&operator=LianTong&revision=$revision" "$cookie_one")"
printf '%s' "$update" | body | jq -e '.success and .data.username == "teacher02" and .data.account_type == "teacher" and .data.operator == "default" and .data.proxy_url == "http://127.0.0.1:7890"' >/dev/null
stale="$(run_cgi account.sh POST "username=teacher03&password=another&operator=LianTong&revision=$revision" "$cookie_one")"
[[ "$stale" == *'409 Conflict'* ]]
printf '%s' "$stale" | body | jq -e '.code == "CONFLICT"' >/dev/null

run_cgi auth.sh POST 'action=logout' "$cookie_two" | body | jq -e '.success' >/dev/null
run_cgi account.sh GET '' "$cookie_one" | body | jq -e '.success' >/dev/null
logged_out="$(run_cgi account.sh GET '' "$cookie_two")"
[[ "$logged_out" == *'401 Unauthorized'* ]]
grep -Fx 'PASSWORD=next-pass' "$CONFIG_FILE" >/dev/null
printf '%s\n' 'PASS: auth, independent sessions, real-core account update, retained teacher/proxy data, revision conflict'

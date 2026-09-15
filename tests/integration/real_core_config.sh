#!/bin/bash
# Real core + CGI configuration boundary. No campus auth or service operations.
set -euE
trap 'printf "real core regression failed at line %s\n" "$LINENO" >&2' ERR
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
: "${RUIJIECTL:?Set RUIJIECTL to the checked-out real core executable}"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export CONFIG_DIR="$scratch/config" CONFIG_FILE="$scratch/config/account.conf"
export RUIJIE_CONFIG_HOME="$scratch/config"
export RUIJIE_PANEL_AUTH_DIR="$scratch/auth"
export RUIJIE_PANEL_SESSION_DIR="$scratch/sessions"
export RUIJIE_PANEL_RATE_DIR="$scratch/rate"
mkdir -p "$RUIJIE_PANEL_AUTH_DIR"
printf 'PASSWORD_SHA256=%s\n' "$(printf '%s' panel-test | sha256sum | cut -d' ' -f1)" > "$RUIJIE_PANEL_AUTH_DIR/auth.conf"
printf '%s' '{"revision":"0","username":"teacher","password":"secret","account_type":"teacher","operator":"default","proxy_url":"http://127.0.0.1:7890","proxy_url_https":""}' | "$RUIJIECTL" config set | jq -e '.success' >/dev/null
cgi() {
    local script="$1" method="$2" body="${3:-}"
    printf '%s' "$body" | env REQUEST_METHOD="$method" CONTENT_TYPE=application/x-www-form-urlencoded CONTENT_LENGTH="${#body}" REMOTE_ADDR=127.0.0.1 sh "$ROOT/api/$script.sh"
}
json() { sed '1,/^\r$/d'; }
unauthorized="$(cgi account GET)"
[[ "$unauthorized" == *'401 Unauthorized'* ]]
login="$(cgi auth POST 'password=panel-test')"
token="$(printf '%s\n' "$login" | sed -n 's/^Set-Cookie: ruijie_panel_session=\([^;]*\).*/\1/p')"
[ "${#token}" -eq 32 ]
export HTTP_COOKIE="ruijie_panel_session=$token"
current="$(cgi account GET | json)"
revision="$(printf '%s' "$current" | jq -er '.data.revision')"
body="username=teacher2&password=changed&operator=DianXin&revision=$revision"
cgi account POST "$body" | json | jq -e '.success and .data.username == "teacher2" and .data.account_type == "teacher" and .data.operator == "default" and .data.proxy_url == "http://127.0.0.1:7890"' >/dev/null
replay="$(cgi account POST "$body")"
[[ "$replay" == *'409 Conflict'* ]]
printf '%s' "$replay" | json | jq -e '.code == "CONFLICT"' >/dev/null
grep -Fx 'PASSWORD=changed' "$CONFIG_FILE" >/dev/null
printf '%s\n' 'PASS: real CGI auth, real core account save, teacher/proxy preservation, stale revision conflict'

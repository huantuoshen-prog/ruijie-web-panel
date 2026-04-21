#!/bin/sh
. "$(dirname "$0")/common.sh"

panel_require_auth || exit 0

echo "Content-Type: application/json; charset=utf-8"
echo ""

log="${PANEL_LOGFILE}"
[ ! -f "$log" ] && echo '{"lines":[],"total":0}' && exit 0

tmp_log="$(mktemp)"
tail -n 200 "$log" 2>/dev/null > "$tmp_log"

esc="$(printf '\033')"
sep=""
count=0
printf '{"lines":['
while IFS= read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  clean_line="$(printf '%s' "$line" | sed "s/${esc}\[[0-9;]*m//g" | tr -d '\r')"
  timestamp="$(printf '%s' "$clean_line" | sed -n 's/^\[\([^]]*\)\].*/\1/p')"
  level="INFO"
  case "$clean_line" in
    *'[OK]'*) level="OK" ;;
    *'[WARN]'*) level="WARN" ;;
    *'[ERROR]'*) level="ERROR" ;;
    *'[STEP]'*) level="STEP" ;;
    *'[ONLINE]'*) level="ONLINE" ;;
  esac
  message="$(printf '%s' "$clean_line" | sed 's/^\[[^]]*\][[:space:]]*//')"
  printf '%s{"ts":"%s","level":"%s","msg":"%s"}' \
    "$sep" \
    "$(json_esc "${timestamp:-}")" \
    "$(json_esc "$level")" \
    "$(json_esc "$message")"
  sep=","
  count=$((count + 1))
done < "$tmp_log"
printf '],"total":%s}' "$count"
rm -f "$tmp_log"

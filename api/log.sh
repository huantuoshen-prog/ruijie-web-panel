#!/bin/sh
. "$(dirname "$0")/common.sh"

panel_require_auth || exit 0

echo "Content-Type: application/json; charset=utf-8"
echo ""

log="${PANEL_LOGFILE}"
[ ! -f "$log" ] && echo '{"lines":[],"total":0}' && exit 0

level="$(printf '%s' "${QUERY_STRING:-}" | sed -n 's/.*level=\([^&]*\).*/\1/p')"
tmp_log="$(mktemp)"
tail -n 200 "$log" 2>/dev/null > "$tmp_log"

echo -n '{"lines":['
sep=""
count=0
while IFS= read -r L || [ -n "$L" ]; do
  [ -z "$L" ] && continue
  C=$(echo "$L" | tr -d '[-]')
  T=$(echo "$C" | awk '{gsub(/\[|\]/,""); print $1, $2}' | tr -d '\n')
  case "$T" in *-*:*:*) ;; *) T="" ;; esac
  K="INFO"
  case "$L" in
    *'[OK]'*)     K="OK" ;;
    *'[WARN]'*)   K="WARN" ;;
    *'[ERROR]'*)  K="ERROR" ;;
    *'[STEP]'*)   K="STEP" ;;
    *'[ONLINE]'*) K="ONLINE" ;;
  esac
  if [ -n "$level" ] && [ "$K" != "$level" ]; then
    continue
  fi
  M=$(echo "$C" | awk '{for(i=1;i<=NF;i++)if($i~/^[0-9]{4}-[0-9]{2}$/)break;for(i++;i<=NF;i++)printf "%s ",$i;print ""}')
  printf '%s{"ts":"%s","level":"%s","msg":"%s"}' "$sep" "$(json_esc "$T")" "$(json_esc "$K")" "$(json_esc "$M")"
  sep=","
  count=$((count+1))
done < "$tmp_log"
rm -f "$tmp_log"
printf '],"total":%s}' "$count"

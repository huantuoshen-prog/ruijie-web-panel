#!/bin/sh
echo "Content-Type: application/json; charset=utf-8"
echo ""
log="/var/log/ruijie-daemon.log"
[ ! -f "$log" ] && echo '{"lines":[],"total":0}' && exit 0
echo -n '{"lines":['
sep=""
count=0
tail -n 200 "$log" 2>/dev/null | while IFS= read -r L; do
  [ -z "$L" ] && continue
  count=$((count+1))
  # 去掉控制字符
  C=$(echo "$L" | tr -d '[-]')
  # 提取时间戳
  T=$(echo "$C" | awk '{gsub(/\[|\]/,""); print $1, $2}' | tr -d '
')
  case "$T" in *-*:*:*) ;; *) T="" ;; esac
  # 级别
  K="INFO"
  case "$L" in
    *'[OK]'*)    K="OK" ;;
    *'[WARN]'*) K="WARN" ;;
    *'[ERROR]'*) K="ERROR" ;;
    *'[STEP]'*) K="STEP" ;;
    *'[ONLINE]'*) K="ONLINE" ;;
  esac
  # 消息：去掉 [ONLINE] 等标签前缀
  M=$(echo "$C" | awk '{for(i=1;i<=NF;i++)if($i~/^[0-9]{4}-[0-9]{2}$/)break;for(i++;i<=NF;i++)printf "%s ",$i;print ""}')
  echo "{\"ts\":\"$T\",\"level\":\"$K\",\"msg\":\"$M\"}"
  sep=","
done
echo '],"total":'$count'}'

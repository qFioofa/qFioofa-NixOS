#!/usr/bin/env bash
read_cpu() {
  read -r _ a b c d e f g _ < /proc/stat
  total=$(( a + b + c + d + e + f + g )); idle=$(( d + e ))
}
cpu_temp() {
  for z in /sys/class/thermal/thermal_zone*; do
    case "$(@cat@ "$z/type" 2>/dev/null)" in
      x86_pkg_temp|TCPU|acpitz)
        t=$(@cat@ "$z/temp" 2>/dev/null); [ -n "$t" ] && { echo $(( t / 1000 )); return; } ;;
    esac
  done
}
read_cpu; pt=$total; pi=$idle
while :; do
 {
  read_cpu
  dt=$(( total - pt )); di=$(( idle - pi )); pt=$total; pi=$idle
  cpup=0; [ "$dt" -gt 0 ] && cpup=$(( (dt - di) * 100 / dt ))
  if   [ "$cpup" -ge 80 ]; then cc=31; elif [ "$cpup" -ge 40 ]; then cc=93; else cc=32; fi
  temp=$(cpu_temp); ts=""; [ -n "$temp" ] && ts=$(printf '  \033[90m%s°C\033[0m' "$temp")
  printf '\033[36m󰻠\033[0m  %s \033[90m%s%%\033[0m%s\n' "$(@bar@ "$cpup" 7 "$cc")" "$cpup" "$ts"

  read -r l1 l5 l15 _ < /proc/loadavg
  printf '\033[34m󰓅\033[0m  \033[37m%s\033[0m \033[90m%s %s\033[0m\n' "$l1" "$l5" "$l15"

  mt=$(@awk@ '/^MemTotal:/{print $2}' /proc/meminfo)
  ma=$(@awk@ '/^MemAvailable:/{print $2}' /proc/meminfo)
  if [ -n "$mt" ] && [ "$mt" -gt 0 ]; then
    usedp=$(( (mt - ma) * 100 / mt ))
    ug=$(@awk@ -v t="$mt" -v a="$ma" 'BEGIN{printf "%.1f",(t-a)/1048576}')
    tg=$(@awk@ -v t="$mt" 'BEGIN{printf "%.0f",t/1048576}')
    printf '\033[35m󰍛\033[0m  %s \033[90m%sG/%sG\033[0m\n' "$(@bar@ "$usedp" 7 35)" "$ug" "$tg"
  fi

  # Root filesystem usage with a primary bar + free space.
  dline=$(@df@ -h --output=pcent,avail / 2>/dev/null | @tail@ -n1)
  if [ -n "$dline" ]; then
    dp=$(printf '%s' "$dline" | @awk@ '{gsub(/%/,"",$1);print $1+0}')
    dav=$(printf '%s' "$dline" | @awk@ '{print $2}')
    printf '\033[33m󰋊\033[0m  %s \033[90m%s своб\033[0m\n' "$(@bar@ "$dp" 7 33)" "$dav"
  fi

  # Uptime from /proc/uptime (seconds).
  up=$(@cat@ /proc/uptime); up=${up%%.*}
  d=$(( up / 86400 )); hh=$(( up % 86400 / 3600 )); mm=$(( up % 3600 / 60 ))
  u=""; [ "$d" -gt 0 ] && u="${d}д "
  printf '\033[32m󰅐\033[0m  \033[37m%s%dч %dм\033[0m\n' "$u" "$hh" "$mm"
 } | @centerTop@
 @sleep@ 5
done

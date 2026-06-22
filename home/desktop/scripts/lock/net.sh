#!/usr/bin/env bash
while :; do
 {
  w=$(@nmcli@ -t -f IN-USE,SSID,SIGNAL dev wifi 2>/dev/null \
    | @awk@ -F: '$1=="*"{print $2"|"$3; exit}')
  if [ -n "$w" ]; then
    ssid=${w%|*}; sig=${w#*|}; : "${sig:=0}"
    if   [ "$sig" -ge 75 ]; then g='▂▄▆█'; c=32
    elif [ "$sig" -ge 50 ]; then g='▂▄▆ '; c=93
    elif [ "$sig" -ge 25 ]; then g='▂▄   '; c=93
    else                         g='▂    '; c=31; fi
    [ ${#ssid} -gt 16 ] && ssid="${ssid:0:15}…"
    printf '\033[34m󰖩\033[0m  \033[37m%s\033[0m  \033[%dm%s\033[0m\n' "$ssid" "$c" "$g"
  else
    printf '\033[90m󰖪  нет сети\033[0m\n'
  fi
  ipaddr=$(@ip@ route get 1.1.1.1 2>/dev/null \
    | @awk@ '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1);exit}}')
  [ -n "$ipaddr" ] && printf '\033[36m󰩟\033[0m  \033[90m%s\033[0m\n' "$ipaddr"
  vpnif=$(@ip@ -o link show up 2>/dev/null \
    | @awk@ -F': ' '$2 ~ /^(tun|wg|amnezia|proton|nordlynx)/{print $2; exit}')
  [ -n "$vpnif" ] && printf '\033[32m󰦝\033[0m  \033[32mVPN\033[0m \033[90m%s\033[0m\n' "$vpnif"
 } | @centerTop@
 @sleep@ 10
done

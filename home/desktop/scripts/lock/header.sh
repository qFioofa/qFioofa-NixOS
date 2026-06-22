#!/usr/bin/env bash
user=$(@id@ -un 2>/dev/null)
host=$(@uname@ -n 2>/dev/null)
while :; do
  h=$(@date@ +%H)
  if   [ "$h" -lt 5 ];  then greet='󰖔 Доброй ночи'
  elif [ "$h" -lt 12 ]; then greet='󰖜 Доброе утро'
  elif [ "$h" -lt 18 ]; then greet='󰖙 Добрый день'
  else                       greet='󰖛 Добрый вечер'
  fi
  {
    printf '\033[1;35m%s\033[0m\n' "$greet"
    printf '\033[34m󰀄 %s\033[0m\033[90m@%s\033[0m\n' "$user" "$host"
    printf '\033[93m󰃭 %s\033[0m\n' "$(@date@ '+%a, %d %b')"
  } | @centerTop@
  @sleep@ 60
done

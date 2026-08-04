#!/usr/bin/env bash
f="/run/user/$(@id@ -u)/lock-feedback"
seen=0; state=rest; attempt=0; masklen=0; marked=0; ts=0
render() {
  w=$(@tmux@ display -p '#{pane_width}' 2>/dev/null); : "${w:=0}"
  case "$state" in
    rest)  line=$'\033[90m❯ Введите пароль\033[0m' ;;
    check) m=$(@awk@ -v n="$masklen" 'BEGIN{s="";for(i=0;i<n;i++)s=s"●";print s}')
           line=$'\033[33m'"$m  Проверка…"$'\033[0m' ;;
    wrong) line=$'\033[31m'"✗ Неверно · попытка $attempt"$'\033[0m' ;;
  esac
  vis=$(printf '%s' "$line" | @sed@ 's/\x1b\[[0-9;]*m//g')
  pad=$(( (w - ${#vis}) / 2 )); [ "$pad" -lt 0 ] && pad=0
  printf '\033[H\033[2J%*s%s' "$pad" "" "$line"
}
printf '\033[?25l'
render
while :; do
  if [ -r "$f" ]; then
    n=$(@wc@ -l < "$f" 2>/dev/null); : "${n:=0}"
    if [ "$n" -gt "$seen" ]; then
      masklen=$(@tail@ -n1 "$f" | @awk@ '{print $2+0}')
      [ "$masklen" -gt 24 ] && masklen=24
      seen=$n; attempt=$n; state=check; marked=0; ts=$(@date@ +%s); render
    fi
  fi
  if [ "$state" = check ] && [ "$marked" -eq 0 ]; then
    now=$(@date@ +%s)
    [ "$(( now - ts ))" -ge 1 ] && { state=wrong; marked=1; render; }
  fi
  @sleep@ 0.3
done

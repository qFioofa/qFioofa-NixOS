#!/usr/bin/env bash
DATE=@date@
ROFI="@rofi@ -theme @calTheme@"
WLCOPY=@wlcopy@
NOTIFY=@notify@

esc() { printf '%s' "$1" | @sed@ 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

info() {
  printf '<span color="@fgMuted@" weight="bold">󰁍</span>   Back\n' \
    | $ROFI -dmenu -i -markup-rows -p "$1" -mesg "<tt>$(esc "$2")</tt>" -markup \
        -no-custom -format s >/dev/null
}

ask() {
  local prompt="$1" mesg="${2:-Accepts YYYY-MM-DD or natural language (e.g. \"next friday\").}" default="${3:-}"
  if [ -n "$default" ]; then
    : | $ROFI -dmenu -p "$prompt" -mesg "$mesg" -lines 0 -filter "$default"
  else
    : | $ROFI -dmenu -p "$prompt" -mesg "$mesg" -lines 0
  fi
}

to_epoch() { $DATE -d "$1" +%s 2>/dev/null; }

today_details() {
  local now leap doy week left dow
  now=$($DATE +%s)
  dow=$($DATE +%A)
  doy=$($DATE +%-j)
  week=$($DATE +%V)
  left=$(( ( $($DATE -d "$($DATE +%Y)-12-31" +%s) - now ) / 86400 ))
  if $DATE -d "$($DATE +%Y)-02-29" >/dev/null 2>&1; then leap="yes"; else leap="no"; fi
  info "Today" "$($DATE '+%A, %d %B %Y')
Time        $($DATE '+%H:%M:%S %Z')
Day of year $doy
ISO week    $week
Quarter     Q$(( ($($DATE +%-m) - 1) / 3 + 1 ))
Leap year   $leap
Days left   $left in this year
Unix time   $now"
}

days_between() {
  local a b ea eb diff days weeks rem y m d sign last
  a="${1:-}"
  [ -z "$a" ] && a=$(ask "First date" "From which date?")
  [ -z "$a" ] && return
  b=$(ask "Second date" "To which date?")
  [ -z "$b" ] && return
  ea=$(to_epoch "$a"); eb=$(to_epoch "$b")
  if [ -z "$ea" ] || [ -z "$eb" ]; then info "Error" "Could not understand one of those dates."; return; fi
  diff=$(( eb - ea )); sign=""
  if [ "$diff" -lt 0 ]; then diff=$(( -diff )); sign="-"; fi
  days=$(( diff / 86400 )); weeks=$(( days / 7 )); rem=$(( days % 7 ))
  local d1 d2; d1=$($DATE -d "$a" +%Y-%m-%d); d2=$($DATE -d "$b" +%Y-%m-%d)
  if [ "$ea" -gt "$eb" ]; then local t=$d1; d1=$d2; d2=$t; fi
  y=$(( $($DATE -d "$d2" +%Y) - $($DATE -d "$d1" +%Y) ))
  m=$(( $($DATE -d "$d2" +%-m) - $($DATE -d "$d1" +%-m) ))
  d=$(( $($DATE -d "$d2" +%-d) - $($DATE -d "$d1" +%-d) ))
  if [ "$d" -lt 0 ]; then
    m=$(( m - 1 ))
    last=$($DATE -d "$($DATE -d "$d2" +%Y-%m-01) -1 day" +%-d)
    d=$(( d + last ))
  fi
  if [ "$m" -lt 0 ]; then y=$(( y - 1 )); m=$(( m + 12 )); fi
  info "Days between" "$($DATE -d "$a" '+%a %d %b %Y')  →  $($DATE -d "$b" '+%a %d %b %Y')

Total      $sign$days days
           $sign$weeks weeks, $rem days
Calendar   $sign$y years, $m months, $d days"
}

shift_date() {
  local base off res
  base="${1:-}"
  if [ -z "$base" ]; then
    base=$(ask "Base date" "Start from which date? (blank = today)")
    [ -z "$base" ] && base="today"
  fi
  off=$(ask "Offset" "e.g. +10 days, -3 weeks, 2 months, 1 year")
  [ -z "$off" ] && return
  res=$($DATE -d "$base $off" '+%A, %d %B %Y' 2>/dev/null)
  if [ -z "$res" ]; then info "Error" "Could not apply that offset."; return; fi
  info "Shift date" "$($DATE -d "$base" '+%a %d %b %Y')  $off

= $res"
}

weekday_of() {
  local d res
  d="${1:-}"
  [ -z "$d" ] && d=$(ask "Date")
  [ -z "$d" ] && return
  res=$($DATE -d "$d" '+%A, %d %B %Y' 2>/dev/null)
  if [ -z "$res" ]; then info "Error" "Could not understand that date."; return; fi
  info "Day of week" "$res
ISO week $($DATE -d "$d" +%V) · day $($DATE -d "$d" +%-j) of the year"
}

countdown() {
  local d ea now days res when
  d="${1:-}"
  [ -z "$d" ] && d=$(ask "Target date")
  [ -z "$d" ] && return
  ea=$(to_epoch "$d"); now=$($DATE +%s)
  if [ -z "$ea" ]; then info "Error" "Could not understand that date."; return; fi
  days=$(( (ea - now) / 86400 ))
  if [ "$days" -gt 0 ]; then when="$days days from now";
  elif [ "$days" -lt 0 ]; then when="$(( -days )) days ago";
  else when="today"; fi
  info "Countdown" "$($DATE -d "$d" '+%A, %d %B %Y')

$when
($(( (ea - now) / 604800 )) weeks)"
}

unix_convert() {
  local v res
  v=$(ask "Unix timestamp or date" "Enter epoch seconds, or a date to get its epoch.")
  [ -z "$v" ] && return
  if printf '%s' "$v" | @grep@ -Eq '^[0-9]{6,}$'; then
    res=$($DATE -d "@$v" '+%A, %d %B %Y  %H:%M:%S %Z')
    info "Timestamp → date" "$v
= $res"
  else
    res=$(to_epoch "$v")
    if [ -z "$res" ]; then info "Error" "Could not understand that input."; return; fi
    info "Date → timestamp" "$($DATE -d "$v" '+%a %d %b %Y %H:%M')
= $res"
  fi
}

day_details() {
  local d norm now ea diff year_end left doy week dow quarter when
  d="${1:-}"
  [ -z "$d" ] && return
  norm=$($DATE -d "$d" '+%Y-%m-%d' 2>/dev/null)
  if [ -z "$norm" ]; then info "Error" "Could not understand that date."; return; fi
  now=$($DATE +%s)
  ea=$($DATE -d "$norm" +%s)
  diff=$(( (ea - now) / 86400 ))
  if [ "$diff" -gt 0 ]; then when="$diff days from today";
  elif [ "$diff" -lt 0 ]; then when="$(( -diff )) days ago";
  else when="today"; fi
  doy=$($DATE -d "$norm" +%-j)
  week=$($DATE -d "$norm" +%V)
  dow=$($DATE -d "$norm" +%A)
  quarter=$(( ($($DATE -d "$norm" +%-m) - 1) / 3 + 1 ))
  year_end=$($DATE -d "$($DATE -d "$norm" +%Y)-12-31" +%s)
  left=$(( (year_end - ea) / 86400 ))
  info "Day" "$dow, $($DATE -d "$norm" '+%d %B %Y')

ISO week    $week
Quarter     Q$quarter
Day of year $doy
From today  $when
Days left   $left in this year"
}

copy_date() {
  local d="${1:-}"
  [ -z "$d" ] && return
  printf '%s' "$d" | "$WLCOPY"
  "$NOTIFY" "Calendar" "Copied $d" 2>/dev/null || true
}

item() { printf '<span color="%s" weight="bold">%s</span>   %s\n' "$1" "$2" "$3"; }

show_menu() {
  local choice
  choice=$( { \
    item "@primary@" "󰃭" "Today in detail"; \
    item "@tide@"    "󰸗" "Days between two dates"; \
    item "@violet@"  "󱢖" "Add / subtract from a date"; \
    item "@amber@"   "󰔠" "Day of the week"; \
    item "@coral@"   "󰥔" "Countdown to a date"; \
    item "@warning@" "󰓦" "Unix timestamp converter"; \
    item "@fgMuted@" "󰁍" "Back"; \
  } | $ROFI -dmenu -i -markup-rows -p "Date tools" -mesg "Date and time utilities" -markup -no-custom -format s )
  case "$choice" in
    *Today*)     today_details ;;
    *between*)   days_between ;;
    *subtract*)  shift_date ;;
    *week*)      weekday_of ;;
    *Countdown*) countdown ;;
    *Unix*)      unix_convert ;;
    *)           exit 0 ;;
  esac
}

case "${1:-menu}" in
  menu)      show_menu ;;
  today)     today_details ;;
  between)   days_between "${2:-}" ;;
  shift)     shift_date "${2:-}" ;;
  weekday)   weekday_of "${2:-}" ;;
  countdown) countdown "${2:-}" ;;
  unix)      unix_convert ;;
  details)   day_details "${2:-}" ;;
  copy)      copy_date "${2:-}" ;;
  *)         show_menu ;;
esac

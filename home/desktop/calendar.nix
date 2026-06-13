{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme)
    bg bgSurface fg fgDim fgMuted
    primary success warning error
    violet tide amber coral;

  date = "${pkgs.coreutils}/bin/date";
  cal = "${pkgs.util-linux}/bin/cal";
  rofi = "${pkgs.rofi}/bin/rofi";

  # Wider than the powermenu popup: the calendar grid and date readouts need
  # room, and the inputbar is enabled here so date-entry prompts can be typed.
  calTheme = pkgs.writeText "calendar.rasi" ''
    * {
      bg:         ${bg};
      bg-surface: ${bgSurface};
      fg:         ${fg};
      fg-dim:     ${fgDim};
      fg-muted:   ${fgMuted};
      accent:     ${primary};
      danger:     ${error};
      background-color: transparent;
      text-color:       @fg;
    }
    window {
      width:         420px;
      border:        2px;
      border-color:  @accent;
      border-radius: 12px;
      background-color: @bg;
      location: center;
    }
    mainbox {
      padding: 14px;
      spacing: 10px;
      background-color: transparent;
    }
    inputbar {
      padding: 8px 12px;
      spacing: 8px;
      border-radius: 8px;
      background-color: @bg-surface;
      text-color: @fg;
      children: [ prompt, entry ];
    }
    prompt {
      text-color: @accent;
    }
    message {
      padding: 10px 12px;
      border-radius: 8px;
      background-color: @bg-surface;
      text-color: @fg;
    }
    textbox {
      text-color: @fg;
    }
    listview {
      lines:    8;
      spacing:  4px;
      scrollbar: false;
      background-color: transparent;
    }
    element {
      padding:       8px 12px;
      spacing:       12px;
      border-radius: 8px;
      background-color: transparent;
      text-color: @fg-dim;
    }
    element selected {
      background-color: @bg-surface;
      text-color: @accent;
    }
    element-text {
      text-color: inherit;
      vertical-align: 0.5;
    }
  '';

  # A grab-bag of date utilities driven by rofi. Every menu loops back to a
  # main screen so the popup behaves like a small app rather than a one-shot
  # picker. All date parsing leans on GNU `date -d`, which accepts both
  # YYYY-MM-DD and free-form input ("next friday", "25 dec").
  calendar = pkgs.writeShellScriptBin "calendar" ''
    DATE=${date}
    CAL=${cal}
    ROFI="${rofi} -theme ${calTheme}"

    # Pango-escape a string for use in rofi -mesg (markup is on).
    esc() { printf '%s' "$1" | ${pkgs.gnused}/bin/sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

    # info TITLE BODY — show a read-only panel with a single "Back" row.
    info() {
      printf '<span color="${fgMuted}" weight="bold">󰁍</span>   Back\n' \
        | $ROFI -dmenu -i -markup-rows -p "$1" -mesg "<tt>$(esc "$2")</tt>" -markup \
            -no-custom -format s >/dev/null
    }

    # ask PROMPT [PRESET] — show just an inputbar, echo what the user types.
    ask() {
      : | $ROFI -dmenu -p "$1" -mesg "''${2:-Accepts YYYY-MM-DD or natural language (e.g. \"next friday\").}" -lines 0
    }

    # Normalise user input to an epoch; empty on failure.
    to_epoch() { $DATE -d "$1" +%s 2>/dev/null; }

    # Month calendar with prev/next/jump navigation. Argument: offset in months
    # from the current month (0 = this month).
    show_calendar() {
      local off=''${1:-0}
      while :; do
        local first ym mon yr body chosen
        first=$($DATE -d "$($DATE +%Y-%m-01) +$off month" +%Y-%m-01)
        ym=$($DATE -d "$first" "+%B %Y")
        mon=$($DATE -d "$first" +%-m); yr=$($DATE -d "$first" +%Y)
        # cal -m → Monday is the first column; positional month/year selects it.
        body=$($CAL -m "$mon" "$yr")
        # Mark today with a guillemet when we are looking at the current month.
        if [ "$off" -eq 0 ]; then
          local td; td=$($DATE +%-d)
          body=$(printf '%s' "$body" | ${pkgs.gnused}/bin/sed -E "s/(^| )($td)( |$)/\1[\2]\3/")
        fi
        chosen=$( { \
          item "${tide}"    "󰃭" "Prev month"; \
          item "${tide}"    "󰃭" "Next month"; \
          item "${primary}" "󰸗" "Jump to today"; \
          item "${fgMuted}" "󰁍" "Back"; \
        } | $ROFI -dmenu -i -markup-rows -p "$ym" -mesg "<tt>$(esc "$body")</tt>" -markup -no-custom -format s)
        case "$chosen" in
          *Prev*) off=$((off - 1)) ;;
          *Next*) off=$((off + 1)) ;;
          *today*) off=0 ;;
          *) return ;;
        esac
      done
    }

    today_details() {
      local now leap doy week left dow
      now=$($DATE +%s)
      dow=$($DATE +%A)
      doy=$($DATE +%-j)
      week=$($DATE +%V)            # ISO week number
      # Days remaining in the year.
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
      a=$(ask "First date" "From which date?"); [ -z "$a" ] && return
      b=$(ask "Second date" "To which date?");  [ -z "$b" ] && return
      ea=$(to_epoch "$a"); eb=$(to_epoch "$b")
      if [ -z "$ea" ] || [ -z "$eb" ]; then info "Error" "Could not understand one of those dates."; return; fi
      diff=$(( eb - ea )); sign=""
      if [ "$diff" -lt 0 ]; then diff=$(( -diff )); sign="-"; fi
      days=$(( diff / 86400 )); weeks=$(( days / 7 )); rem=$(( days % 7 ))
      # Calendar Y/M/D breakdown (orders the two dates first).
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
      base=$(ask "Base date" "Start from which date? (blank = today)")
      [ -z "$base" ] && base="today"
      off=$(ask "Offset" "e.g. +10 days, -3 weeks, 2 months, 1 year")
      [ -z "$off" ] && return
      res=$($DATE -d "$base $off" '+%A, %d %B %Y' 2>/dev/null)
      if [ -z "$res" ]; then info "Error" "Could not apply that offset."; return; fi
      info "Shift date" "$($DATE -d "$base" '+%a %d %b %Y')  $off

= $res"
    }

    weekday_of() {
      local d res
      d=$(ask "Date"); [ -z "$d" ] && return
      res=$($DATE -d "$d" '+%A, %d %B %Y' 2>/dev/null)
      if [ -z "$res" ]; then info "Error" "Could not understand that date."; return; fi
      info "Day of week" "$res
ISO week $($DATE -d "$d" +%V) · day $($DATE -d "$d" +%-j) of the year"
    }

    countdown() {
      local d ea now days res when
      d=$(ask "Target date"); [ -z "$d" ] && return
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
      if printf '%s' "$v" | ${pkgs.gnugrep}/bin/grep -Eq '^[0-9]{6,}$'; then
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

    # item COLOR ICON LABEL — a list row with an accent-coloured icon so each
    # category reads distinctly instead of one flat colour.
    item() { printf '<span color="%s" weight="bold">%s</span>   %s\n' "$1" "$2" "$3"; }

    while :; do
      choice=$( { \
        item "${primary}" "󰃭" "Calendar"; \
        item "${tide}"    "󰸗" "Today in detail"; \
        item "${violet}"  "󱢖" "Days between two dates"; \
        item "${amber}"   "󰔠" "Add / subtract from a date"; \
        item "${success}" "󱑎" "Day of the week"; \
        item "${coral}"   "󰥔" "Countdown to a date"; \
        item "${warning}" "󰓦" "Unix timestamp converter"; \
      } | $ROFI -dmenu -i -markup-rows -p "Calendar" -no-custom -format s)
      case "$choice" in
        *Calendar)        show_calendar 0 ;;
        *detail)          today_details ;;
        *between*)        days_between ;;
        *subtract*)       shift_date ;;
        *week)            weekday_of ;;
        *Countdown*)      countdown ;;
        *converter)       unix_convert ;;
        *) exit 0 ;;
      esac
    done
  '';
in
{
  home.packages = [ calendar ];
}

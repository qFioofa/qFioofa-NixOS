#!/usr/bin/env bash
while :; do
 {
  for b in /sys/class/power_supply/BAT*; do
    [ -r "$b/capacity" ] || continue
    cap=$(@cat@ "$b/capacity")
    st=$(@cat@ "$b/status" 2>/dev/null)
    case "$st" in Charging) icon='󰂄' ;; *) icon='󰁹' ;; esac
    extra=""
    if [ "$st" = "Charging" ] || [ "$st" = "Discharging" ]; then
      rate=$(@cat@ "$b/power_now" 2>/dev/null)    # µW
      now=$(@cat@ "$b/energy_now" 2>/dev/null)    # µWh
      full=$(@cat@ "$b/energy_full" 2>/dev/null)
      dw=""                                        # draw in deciwatts (0.1 W)
      if [ -n "$rate" ] && [ "$rate" -gt 0 ] 2>/dev/null; then
        dw=$(( rate / 100000 ))
      else
        rate=$(@cat@ "$b/current_now" 2>/dev/null)  # µA
        now=$(@cat@ "$b/charge_now" 2>/dev/null)    # µAh
        full=$(@cat@ "$b/charge_full" 2>/dev/null)
        volt=$(@cat@ "$b/voltage_now" 2>/dev/null)  # µV
        [ -n "$rate" ] && [ "$rate" -gt 0 ] 2>/dev/null && [ -n "$volt" ] \
          && dw=$(( rate * volt / 100000000000 ))
      fi
      if [ -n "$dw" ] && [ "$dw" -gt 0 ] 2>/dev/null; then
        extra=$(printf '  %d.%dW' "$(( dw / 10 ))" "$(( dw % 10 ))")
        rem=""
        [ "$st" = "Discharging" ] && [ -n "$now" ] && rem=$(( now * 60 / rate ))
        [ "$st" = "Charging" ] && [ -n "$now" ] && [ -n "$full" ] && rem=$(( (full - now) * 60 / rate ))
        [ -n "$rem" ] && [ "$rem" -gt 0 ] && extra="$extra $(( rem / 60 ))h$(( rem % 60 ))m"
      fi
    fi
    if [ "$st" = "Charging" ] || { [ "$cap" -ge 50 ] 2>/dev/null; }; then col=32
    elif [ "$cap" -ge 20 ] 2>/dev/null; then col=93
    else col=31; fi
    printf '\033[%dm%s  %s%%\033[0m\033[90m%s\033[0m\n' "$col" "$icon" "$cap" "$extra"
    break
  done

  pstat=$(@playerctl@ status 2>/dev/null)
  if [ "$pstat" = "Playing" ] || [ "$pstat" = "Paused" ]; then
    case "$pstat" in Playing) g='󰐊' ;; *) g='󰏤' ;; esac
    artist=$(@playerctl@ metadata artist 2>/dev/null)
    title=$(@playerctl@ metadata title 2>/dev/null)
    if [ -n "$title" ]; then
      [ -n "$artist" ] && np="$artist — $title" || np="$title"
      [ ${#np} -gt 28 ] && np="${np:0:27}…"
      # Magenta player glyph, title in plain foreground.
      printf '\033[35m%s\033[0m  \033[37m%s\033[0m\n' "$g" "$np"
    fi
  fi
 } | @centerTop@

  @sleep@ 5
done

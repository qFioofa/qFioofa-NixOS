#!/usr/bin/env bash
printf '\033[?25l'
H=$(@tmux@ display -p '#{pane_height}' 2>/dev/null); : "${H:=0}"
W=$(@tmux@ display -p '#{pane_width}'  2>/dev/null); : "${W:=0}"
n=$(@swayncClient@ -c 2>/dev/null)
{
  printf '  󰂚  %s waiting\n' "${n:-0}"
  @dbusMonitor@ --session \
    "interface='org.freedesktop.Notifications',member='Notify'" 2>/dev/null
} | @awk@ -v H="$H" -v W="$W" '
    function render(   i, max, start, line, vis, pad) {
      printf "\033[2J"
      max = (H > 1) ? H : 1
      start = (nl > max) ? nl - max : 0      # keep only the last `max` lines
      # Top-aligned: the trail grows downward from the top of the pane (which
      # sits directly under the status block), so the compact column reads as
      # one continuous stack rather than a feed floating in mid-pane.
      printf "\033[1;1H"
      for (i = start; i < nl; i++) {
        line = lines[i]
        vis = line; gsub(/\033\[[0-9;]*m/, "", vis)
        pad = int((W - length(vis)) / 2); if (pad < 0) pad = 0
        printf "%*s%s\n", pad, "", line
      }
      fflush()
    }
    # Build "  HH:MM  App: summary" (or just the summary when no app name is
    # known). Stored as components so we can rewrite the line in place if the
    # app name only turns up later, in the desktop-entry hint.
    function compose(app, summ) { return (app == "" ? summ : app ": " summ) }
    NR == 1 { lines[nl++] = $0; render(); next }   # the seed "waiting" header
    # A new Notify call: reset the per-message field counter and state.
    /^method call/ { s = 0; app = ""; cur = -1; de = 0; next }
    # Pull the quoted payload out of any line carrying a string (works for
    # both `string "x"` and the hints` `variant ... string "x"`).
    /string "/ {
      if (!match($0, /string "([^"]*)"/, m)) next
      v = m[1]
      # The value right after the `desktop-entry` hint key is the app id;
      # use it only as a fallback when app_name (the 1st string) was empty.
      if (de) {
        de = 0
        if (app == "" && cur >= 0) {
          apps[cur] = v
          lines[cur] = sprintf("  %s  %s", times[cur], compose(v, summs[cur]))
          render()
        }
        next
      }
      if (v == "desktop-entry") { de = 1; next }
      s++
      if (s == 1) app = v                      # app_name (often empty)
      else if (s == 3) {                       # summary → emit the entry
        cur = nl
        times[cur] = strftime("%H:%M"); summs[cur] = v; apps[cur] = app
        lines[nl++] = sprintf("  %s  %s", times[cur], compose(app, v))
        render()
      }
    }
  '

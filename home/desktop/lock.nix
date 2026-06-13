{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme) bg bgSurface fg primary success error font;
  # swaylock wants colours as RRGGBB[AA] without a leading '#'.
  strip = c: builtins.substring 1 (builtins.stringLength c) c;

  # Tool paths — referenced absolutely so the lock screen never depends on the
  # session PATH (it must work from hypridle, before-sleep, etc.).
  swaylock = "${pkgs.swaylock-plugin}/bin/swaylock-plugin";
  windowtolayer = "${pkgs.windowtolayer}/bin/windowtolayer";
  alacritty = "${pkgs.alacritty}/bin/alacritty";
  tmux = "${pkgs.tmux}/bin/tmux";
  asciiquarium = "${pkgs.asciiquarium}/bin/asciiquarium";
  cbonsai = "${pkgs.cbonsai}/bin/cbonsai";
  cmatrix = "${pkgs.cmatrix}/bin/cmatrix";
  pipes = "${pkgs.pipes-rs}/bin/pipes-rs";
  lavat = "${pkgs.lavat}/bin/lavat";
  cal = "${pkgs.util-linux}/bin/cal";
  flock = "${pkgs.util-linux}/bin/flock";
  od = "${pkgs.coreutils}/bin/od";
  cat = "${pkgs.coreutils}/bin/cat";
  wc = "${pkgs.coreutils}/bin/wc";
  date = "${pkgs.coreutils}/bin/date";
  sleep = "${pkgs.coreutils}/bin/sleep";
  awk = "${pkgs.gawk}/bin/awk";
  sed = "${pkgs.gnused}/bin/sed";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  swayncClient = "${pkgs.swaynotificationcenter}/bin/swaync-client";
  dbusMonitor = "${pkgs.dbus}/bin/dbus-monitor";

  # ── Why this is not just swaylock ────────────────────────────────────────
  # A Wayland locker draws *exclusive* lock surfaces (ext-session-lock-v1) and
  # nothing else may render while locked. So plain swaylock/hyprlock can only
  # show their own fixed UI — they cannot run a live terminal animation.
  # swaylock-plugin lifts this: its --command-each runs a wlr-layer-shell
  # wallpaper program as the lock background. windowtolayer turns a normal
  # xdg-shell app (a terminal) into such a wallpaper, so the background is a
  # real terminal. The chain is:
  #     swaylock-plugin → windowtolayer → alacritty → tmux layout
  # swaylock's PAM password ring is drawn on top of all of it.
  #
  # ── Why alacritty and not foot ───────────────────────────────────────────
  # windowtolayer (0.3.x) only partially reimplements the Wayland protocol for
  # the app it hosts. foot trips over a request it doesn't handle: foot logs
  # "failed to roundtrip Wayland display: Connection reset by peer" and dies on
  # connect, so the background never renders — a black lock screen. alacritty is
  # the terminal upstream documents and tests for exactly this setup
  # (swaylock-plugin's README ships `windowtolayer -- alacritty -e asciiquarium`).
  # We also follow the documented invocation: bare `windowtolayer -- <app>`,
  # with no `-m`/`-i` flags (the layer surface already fills the output, and the
  # default interactivity of "none" is what a wallpaper wants).

  # Alacritty tuned for the lock: theme colours, Nerd Font, generous padding,
  # no decorations, a steady block cursor.
  alacrittyConf = pkgs.writeText "lock-alacritty.toml" ''
    [window]
    decorations = "None"
    dynamic_padding = false
    opacity = 1.0
    padding.x = 28
    padding.y = 28

    [font]
    size = 13
    normal.family = "${font}"

    [colors.primary]
    background = "${bg}"
    foreground = "${fg}"

    [cursor]
    style.shape = "Block"
    style.blinking = "Off"

    [mouse]
    hide_when_typing = true
  '';

  # tmux dedicated to the lock screen (own socket + config, never touches the
  # user's tmux). Subtle pane borders make the wide ┃ narrow split read.
  lockTmuxConf = pkgs.writeText "lock-tmux.conf" ''
    set -g status off
    set -g mouse off
    set -g escape-time 0
    set -g default-terminal "tmux-256color"
    set -g pane-border-lines simple
    set -g pane-border-style "fg=${bgSurface}"
    set -g pane-active-border-style "fg=${bgSurface}"
  '';

  # The "activity" pane — a random animation each lock (fish tank, bonsai,
  # matrix, pipes). cbonsai -l is the animated tree.
  activity = pkgs.writeShellScript "lock-activity" ''
    case $(( $(${od} -An -N1 -tu1 /dev/urandom) % 5 )) in
      0) exec ${asciiquarium} ;;
      1) exec ${cbonsai} -l -i -t 0.04 ;;
      2) exec ${cmatrix} -b -u 6 ;;
      3) exec ${lavat} -c red ;;
      *) exec ${pipes} ;;
    esac
  '';

  # Clock pane. tty-clock's block digits (HH:MM:SS ≈ 48 cols) are wider than
  # this 1/3-width column, so it rendered blank — we draw a plain centred text
  # clock instead. The time is a fixed-width string redrawn in place each second
  # (cursor-addressed, no full clear), so it never flickers; we only clear when
  # the pane is first drawn or its size changes.
  clockPane = pkgs.writeShellScript "lock-clock" ''
    printf '\033[?25l'                       # hide cursor
    pw=""; ph=""
    while :; do
      h=$(${tmux} display -p '#{pane_height}' 2>/dev/null); : "''${h:=0}"
      w=$(${tmux} display -p '#{pane_width}'  2>/dev/null); : "''${w:=0}"
      if [ "$w" != "$pw" ] || [ "$h" != "$ph" ]; then
        printf '\033[2J'; pw=$w; ph=$h
      fi
      t=$(${date} '+%H:%M:%S')
      row=$(( h / 2 + 1 )); [ "$row" -lt 1 ] && row=1
      col=$(( (w - ''${#t}) / 2 + 1 )); [ "$col" -lt 1 ] && col=1
      printf '\033[%d;%dH%s' "$row" "$col" "$t"
      ${sleep} 1
    done
  '';

  # Centre stdin both ways inside the current tmux pane. Inside a pane $TMUX is
  # set, so plain tmux targets the screenlock server/pane and reports its live
  # size. We clear the pane, print enough leading blank rows to push the block
  # to the vertical middle, then left-pad every line to the horizontal middle.
  # Width is measured with ANSI colour escapes stripped (so cal's highlighted
  # "today" doesn't throw the alignment off); the lines are printed unstripped.
  center = pkgs.writeShellScript "lock-center" ''
    h=$(${tmux} display -p '#{pane_height}' 2>/dev/null)
    w=$(${tmux} display -p '#{pane_width}'  2>/dev/null)
    : "''${h:=0}" "''${w:=0}"
    content=$(${cat})
    nlines=$(printf '%s\n' "$content" | ${wc} -l)
    width=$(printf '%s\n' "$content" \
      | ${sed} 's/\x1b\[[0-9;]*m//g' \
      | ${awk} '{ if (length > m) m = length } END { print m + 0 }')
    top=$(( (h - nlines) / 2 )); [ "$top" -lt 0 ] && top=0
    left=$(( (w - width) / 2 )); [ "$left" -lt 0 ] && left=0
    pad=$(printf '%*s' "$left" "")
    printf '\033[H\033[2J'
    i=0; while [ "$i" -lt "$top" ]; do printf '\n'; i=$(( i + 1 )); done
    printf '%s\n' "$content" | while IFS= read -r line; do
      printf '%s%s\n' "$pad" "$line"
    done
  '';

  # Like `center`, but horizontal only: content is left-padded to the middle of
  # the pane yet pinned to the TOP row (no leading blank rows). Used by the
  # compact right-column stack so each widget hugs the top of its (content-sized)
  # pane and the panes read as one tight block instead of floating mid-pane.
  centerTop = pkgs.writeShellScript "lock-center-top" ''
    w=$(${tmux} display -p '#{pane_width}' 2>/dev/null); : "''${w:=0}"
    content=$(${cat})
    width=$(printf '%s\n' "$content" \
      | ${sed} 's/\x1b\[[0-9;]*m//g' \
      | ${awk} '{ if (length > m) m = length } END { print m + 0 }')
    left=$(( (w - width) / 2 )); [ "$left" -lt 0 ] && left=0
    pad=$(printf '%*s' "$left" "")
    printf '\033[H\033[2J'
    printf '%s\n' "$content" | while IFS= read -r line; do
      printf '%s%s\n' "$pad" "$line"
    done
  '';

  # Calendar pane: the current month, today highlighted, top-aligned in its
  # (content-sized) pane. The compact column is narrow and the layout sizes this
  # pane to a single month, so we drop the earlier 3-month stack here — it
  # belongs to the roomier "fill" layout, not this tight one. --color=always
  # keeps the "today" highlight when piped (cal otherwise drops it once stdout is
  # not a tty); `centerTop` clears the pane and pins the block to the top.
  calPane = pkgs.writeShellScript "lock-cal" ''
    while :; do
      ${cal} --color=always | ${centerTop}
      ${sleep} 1800
    done
  '';

  # Status pane: battery + now-playing. Battery reports charge %, a charging
  # glyph, and — while actually (dis)charging — the draw in watts and time
  # remaining, supporting both sysfs conventions (energy/power µWh/µW and
  # charge/current µAh/µA, with voltage for W). Now-playing is hidden when no
  # MPRIS player is active; the title is kept short for the narrow column.
  statusPane = pkgs.writeShellScript "lock-status" ''
    while :; do
     {
      for b in /sys/class/power_supply/BAT*; do
        [ -r "$b/capacity" ] || continue
        cap=$(${cat} "$b/capacity")
        st=$(${cat} "$b/status" 2>/dev/null)
        case "$st" in Charging) icon='󰂄' ;; *) icon='󰁹' ;; esac
        extra=""
        if [ "$st" = "Charging" ] || [ "$st" = "Discharging" ]; then
          rate=$(${cat} "$b/power_now" 2>/dev/null)    # µW
          now=$(${cat} "$b/energy_now" 2>/dev/null)    # µWh
          full=$(${cat} "$b/energy_full" 2>/dev/null)
          dw=""                                        # draw in deciwatts (0.1 W)
          if [ -n "$rate" ] && [ "$rate" -gt 0 ] 2>/dev/null; then
            dw=$(( rate / 100000 ))
          else
            rate=$(${cat} "$b/current_now" 2>/dev/null)  # µA
            now=$(${cat} "$b/charge_now" 2>/dev/null)    # µAh
            full=$(${cat} "$b/charge_full" 2>/dev/null)
            volt=$(${cat} "$b/voltage_now" 2>/dev/null)  # µV
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
        printf '  %s  %s%%%s\n' "$icon" "$cap" "$extra"
        break
      done

      pstat=$(${playerctl} status 2>/dev/null)
      if [ "$pstat" = "Playing" ] || [ "$pstat" = "Paused" ]; then
        case "$pstat" in Playing) g='󰐊' ;; *) g='󰏤' ;; esac
        artist=$(${playerctl} metadata artist 2>/dev/null)
        title=$(${playerctl} metadata title 2>/dev/null)
        if [ -n "$title" ]; then
          [ -n "$artist" ] && np="$artist — $title" || np="$title"
          [ ''${#np} -gt 28 ] && np="''${np:0:27}…"
          printf '  %s  %s\n' "$g" "$np"
        fi
      fi
     } | ${centerTop}

      ${sleep} 5
    done
  '';

  # Notifications trail: a live feed of notifications as they arrive while
  # locked. We tap the session bus directly (dbus-monitor on the freedesktop
  # Notifications Notify method) rather than swaync — swaync's CLI only exposes
  # a count, not bodies. The Notify signature is (s u s s s as a{sv} i): the 1st
  # string is app_name, 2nd app_icon, 3rd summary, 4th body. Many apps send an
  # EMPTY app_name and only identify themselves via the `desktop-entry` hint
  # (a{sv}), so we fall back to that to label which app a notification is from.
  # The pane's own scrollback is the "trail"; we seed it with swaync's count.
  notifsPane = pkgs.writeShellScript "lock-notifs" ''
    printf '\033[?25l'
    H=$(${tmux} display -p '#{pane_height}' 2>/dev/null); : "''${H:=0}"
    W=$(${tmux} display -p '#{pane_width}'  2>/dev/null); : "''${W:=0}"
    n=$(${swayncClient} -c 2>/dev/null)
    # Feed the seed "waiting" header (line 1) and then the live Notify stream
    # into awk, which keeps the recent lines and re-renders the whole block
    # centred (vertically and horizontally) in the pane on every new entry — a
    # plain stream can only append top-down, which is why it never centred.
    {
      printf '  󰂚  %s waiting\n' "''${n:-0}"
      ${dbusMonitor} --session \
        "interface='org.freedesktop.Notifications',member='Notify'" 2>/dev/null
    } | ${awk} -v H="$H" -v W="$W" '
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
  '';

  # Builds the tmux layout: a wide ~85% activity animation on the left and a
  # narrow ~15% right column. The column is a *compact* top-anchored stack — the
  # notifications trail owns the column, then fixed-height widgets are inserted
  # ABOVE it (`-b`) top→bottom as clock, calendar, status, so the widgets form
  # one tight block at the top (each sized to its content, no centring gaps) and
  # the notifications trail fills whatever is left down to the bottom edge. Then
  # attaches so the terminal renders it. The (transparent) unlock indicator is
  # drawn by swaylock on top, so nothing is overlaid.
  lockLayout = pkgs.writeShellScript "lock-layout" ''
    T="${tmux} -L screenlock -f ${lockTmuxConf}"
    $T kill-server 2>/dev/null || true
    # Each split is targeted at an explicit pane id (captured with -P), so the
    # layout never depends on which pane tmux happens to leave "active". The
    # right column starts as the notifications pane; `-b -l N` inserts each fixed
    # widget directly ABOVE it with an absolute height of N rows (clock 3, the
    # current-month calendar 8, status 3), leaving the rest to notifications.
    left=$($T   new-session   -d    -P -F '#{pane_id}' -s lock       "${activity}")
    notifs=$($T split-window -h     -P -F '#{pane_id}' -t "$left"    -l 15% "${notifsPane}")
    clock=$($T  split-window -v -b  -P -F '#{pane_id}' -t "$notifs"  -l 3   "${clockPane}")
    cal=$($T    split-window -v -b  -P -F '#{pane_id}' -t "$notifs"  -l 8   "${calPane}")
    $T          split-window -v -b                     -t "$notifs"  -l 3   "${statusPane}"
    # Attach in the foreground. When the terminal dies on unlock the client gets
    # SIGHUP and returns here, so we tear the (otherwise detached) server down
    # instead of leaking a screenlock tmux server that keeps animating between
    # locks.
    $T attach -t lock
    $T kill-server 2>/dev/null || true
  '';

  # The background program swaylock-plugin runs: alacritty, adapted to a
  # wlr-layer-shell wallpaper by windowtolayer, showing the tmux layout.
  lockBackground = pkgs.writeShellScript "lock-background" ''
    # Drop the inherited single-instance flock (fd 9 from `lock`). swaylock keeps
    # its own copy, so the lock is still released when swaylock exits — but the
    # detached `screenlock` tmux server spawned below (a daemon that survives
    # unlock) must NOT keep fd 9 open, or it holds the flock forever and every
    # later `lock` silently no-ops on `flock -n 9`.
    exec 9>&-
    exec ${windowtolayer} -- \
      ${alacritty} --config-file ${alacrittyConf} -e ${lockLayout}
  '';

  # No indicator at all. Every part of swaylock's widget — the resting ring and
  # disc, the per-keypress highlight arc ("pulse"), and the verifying / wrong /
  # cleared state rings and their text — is fully transparent, so swaylock draws
  # nothing whatsoever. While locked the screen is purely the ASCII animation;
  # there is no graphical ring or keystroke feedback (swaylock holds the input
  # grab, so the ASCII panes can't show typing either — that's by design here).
  transparent = "00000000";
  swaylockColors = builtins.concatStringsSep " " [
    "--color ${strip bg}"
    # Inside disc — transparent in every state.
    "--inside-color ${transparent}"
    "--inside-ver-color ${transparent}"
    "--inside-wrong-color ${transparent}"
    "--inside-clear-color ${transparent}"
    # Ring — transparent in every state (resting, verifying, wrong, cleared).
    "--ring-color ${transparent}"
    "--ring-ver-color ${transparent}"
    "--ring-wrong-color ${transparent}"
    "--ring-clear-color ${transparent}"
    # Keypress / backspace pulse — transparent, so typing draws no arc.
    "--key-hl-color ${transparent}"
    "--bs-hl-color ${transparent}"
    # All indicator text — transparent in every state.
    "--text-color ${transparent}"
    "--text-ver-color ${transparent}"
    "--text-wrong-color ${transparent}"
    "--text-clear-color ${transparent}"
    "--line-color ${transparent}"
    "--separator-color ${transparent}"
    # Keyboard-layout box (us,ru) kept invisible to stay minimal.
    "--layout-bg-color ${transparent}"
    "--layout-text-color ${transparent}"
    "--layout-border-color ${transparent}"
  ];

  # The single entry point. Everything (keybind, powermenu, swaync, hypridle)
  # locks via `lock`, so we never get a bare-swaylock instance without the
  # animated background, and we guard against double-locking.
  lockBin = pkgs.writeShellScriptBin "lock" ''
    # Race-free single-instance guard: hold an flock for the whole lifetime of
    # swaylock (fd 9 survives the exec below, so the lock is released only when
    # swaylock exits). A plain `pgrep` check-then-spawn races when two triggers
    # fire together — which is exactly how two swaylock instances ended up
    # fighting over the single ext-session-lock and breaking the display.
    exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/swaylock.lock"
    ${flock} -n 9 || exit 0

    # No indicator: every swaylock colour is transparent (see swaylockColors) and
    # the radius/thickness are collapsed to 0, so swaylock never draws a ring or
    # keypress pulse — the screen is purely the ASCII animation. We also omit
    # --indicator-idle-visible so nothing is drawn at rest.
    exec ${swaylock} \
      -f -k -F -e \
      --grace 2 --pointer-hysteresis 25 \
      --font "${font}" \
      --indicator-radius 0 --indicator-thickness 0 \
      ${swaylockColors} \
      --command-each "${lockBackground}"
  '';
in
{
  home.packages = [ lockBin ];

  # Idle management. hypridle uses ext-idle-notify-v1, which niri implements,
  # and respects idle inhibitors (e.g. the waybar toggle, video playback).
  # The display is intentionally never powered off (or dimmed to black) on
  # idle — instead the session locks after a while, so the panel stays lit
  # showing the lock screen rather than going dark. We still lock before the
  # machine sleeps; manual `lock` and loginctl lock-session are unaffected.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${lockBin}/bin/lock";
        before_sleep_cmd = "${lockBin}/bin/lock";
        after_sleep_cmd = "niri msg action power-on-monitors";
      };
      listener = [
        {
          timeout = 600; # 10 min idle → lock the session (screen stays on).
          on-timeout = "${lockBin}/bin/lock";
        }
      ];
    };
  };
}

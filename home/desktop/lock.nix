{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme) bg bgSurface fg fgMuted primary success warning error violet tide coral font;
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
  tail = "${pkgs.coreutils}/bin/tail";
  id = "${pkgs.coreutils}/bin/id";
  uname = "${pkgs.coreutils}/bin/uname";
  awk = "${pkgs.gawk}/bin/awk";
  sed = "${pkgs.gnused}/bin/sed";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  swayncClient = "${pkgs.swaynotificationcenter}/bin/swaync-client";
  dbusMonitor = "${pkgs.dbus}/bin/dbus-monitor";
  df = "${pkgs.coreutils}/bin/df";
  tr = "${pkgs.coreutils}/bin/tr";
  grep = "${pkgs.gnugrep}/bin/grep";
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  ip = "${pkgs.iproute2}/bin/ip";
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";

  # Shared coloured progress bar used by the system / hardware panes: $1=percent
  # $2=cells $3=SGR colour. Filled cells in that colour, empty cells muted, so a
  # value reads by hue and fill at a glance. Factored out so every gauge (memory,
  # disk, CPU, volume, brightness) draws identically.
  bar = pkgs.writeShellScript "lock-bar" ''
    ${pkgs.gawk}/bin/awk -v p="$1" -v w="$2" -v c="$3" 'BEGIN{
      f=int(p*w/100+0.5); if(f>w)f=w; if(f<0)f=0;
      s="\033[" c "m"; for(i=0;i<f;i++) s=s"█";
      s=s"\033[90m"; for(i=f;i<w;i++) s=s"░";
      printf "%s\033[0m", s;
    }'
  '';

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

    # The 16-colour ANSI palette is mapped to the theme so every animation
    # (cmatrix green, lavat red, pipes' random colours, bonsai) renders in our
    # tokens instead of clashing defaults — and so the feedback pane can use
    # plain SGR codes (33 = primary, 31 = error, 90 = muted) and stay on-theme.
    [colors.normal]
    black   = "${bgSurface}"
    red     = "${error}"
    green   = "${success}"
    yellow  = "${primary}"
    blue    = "${tide}"
    magenta = "${violet}"
    cyan    = "${tide}"
    white   = "${fg}"

    [colors.bright]
    black   = "${fgMuted}"
    red     = "${coral}"
    green   = "${success}"
    yellow  = "${warning}"
    blue    = "${tide}"
    magenta = "${violet}"
    cyan    = "${tide}"
    white   = "${fg}"

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
    # Weighted toward the calmer, on-palette animations; cmatrix (busiest) is
    # rarest. Colours now come from the themed ANSI palette in alacrittyConf.
    case $(( $(${od} -An -N1 -tu1 /dev/urandom) % 8 )) in
      0|1) exec ${asciiquarium} ;;
      2|3) exec ${cbonsai} -l -i -t 0.04 ;;
      4)   exec ${cmatrix} -b -u 6 ;;
      5)   exec ${lavat} -c red ;;
      *)   exec ${pipes} ;;
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
      # Colour the colons muted so the HH MM SS groups read as bold primary
      # digits separated by quiet ticks (more colour than a flat single hue).
      hms=$(${date} '+%H:%M:%S')
      t=$(printf '%s' "$hms" | ${sed} 's/:/\x1b[90m:\x1b[1;33m/g')
      row=$(( h / 2 + 1 )); [ "$row" -lt 1 ] && row=1
      col=$(( (w - ''${#hms}) / 2 + 1 )); [ "$col" -lt 1 ] && col=1
      printf '\033[%d;%dH\033[1;33m%s\033[0m' "$row" "$col" "$t"
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
      # cal already reverse-highlights "today"; on top of that we tint the month
      # title (line 1) primary and the weekday row (line 2) tide, so the block
      # carries colour instead of being a flat grey grid. centerTop strips the
      # SGR codes when measuring width, so the colouring never skews alignment.
      ${cal} --color=always \
        | ${awk} 'NR==1{printf "\033[1;33m%s\033[0m\n",$0;next}
                  NR==2{printf "\033[34m%s\033[0m\n",$0;next}
                  {print}' \
        | ${centerTop}
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
        # Colour the level: green when healthy or charging, amber under 50%,
        # red under 20% — a glance at the hue reads the battery state.
        if [ "$st" = "Charging" ] || { [ "$cap" -ge 50 ] 2>/dev/null; }; then col=32
        elif [ "$cap" -ge 20 ] 2>/dev/null; then col=93
        else col=31; fi
        printf '\033[%dm%s  %s%%\033[0m\033[90m%s\033[0m\n' "$col" "$icon" "$cap" "$extra"
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
          # Magenta player glyph, title in plain foreground.
          printf '\033[35m%s\033[0m  \033[37m%s\033[0m\n' "$g" "$np"
        fi
      fi
     } | ${centerTop}

      ${sleep} 5
    done
  '';

  # System pane: live CPU load + temperature, load average, memory, root-disk
  # usage and uptime. Each line is an icon + a value in its own colour, with a
  # small coloured bar on the gauges so the column carries real colour instead
  # of plain text. All data comes from /proc, /sys and `df` (no extra daemons).
  # CPU% is a delta of /proc/stat across the 5s refresh; temp is the CPU package
  # sensor (x86_pkg_temp, falling back to TCPU/acpitz).
  sysPane = pkgs.writeShellScript "lock-sys" ''
    # Snapshot total / idle jiffies from /proc/stat line 1 into $total / $idle.
    read_cpu() {
      read -r _ a b c d e f g _ < /proc/stat
      total=$(( a + b + c + d + e + f + g )); idle=$(( d + e ))
    }
    # CPU package temperature in whole °C from the first matching thermal zone.
    cpu_temp() {
      for z in /sys/class/thermal/thermal_zone*; do
        case "$(${cat} "$z/type" 2>/dev/null)" in
          x86_pkg_temp|TCPU|acpitz)
            t=$(${cat} "$z/temp" 2>/dev/null); [ -n "$t" ] && { echo $(( t / 1000 )); return; } ;;
        esac
      done
    }
    read_cpu; pt=$total; pi=$idle
    while :; do
     {
      # CPU usage: jiffy delta since last tick → busy %, plus package temp. The
      # bar colours by load (green→amber→red) so a spike is visible by hue.
      read_cpu
      dt=$(( total - pt )); di=$(( idle - pi )); pt=$total; pi=$idle
      cpup=0; [ "$dt" -gt 0 ] && cpup=$(( (dt - di) * 100 / dt ))
      if   [ "$cpup" -ge 80 ]; then cc=31; elif [ "$cpup" -ge 40 ]; then cc=93; else cc=32; fi
      temp=$(cpu_temp); ts=""; [ -n "$temp" ] && ts=$(printf '  \033[90m%s°C\033[0m' "$temp")
      printf '\033[36m󰻠\033[0m  %s \033[90m%s%%\033[0m%s\n' "$(${bar} "$cpup" 7 "$cc")" "$cpup" "$ts"

      # 1/5/15-minute load average; the 1-min figure stands out, the rest muted.
      read -r l1 l5 l15 _ < /proc/loadavg
      printf '\033[34m󰓅\033[0m  \033[37m%s\033[0m \033[90m%s %s\033[0m\n' "$l1" "$l5" "$l15"

      # Memory: used / total in GiB with a violet bar.
      mt=$(${awk} '/^MemTotal:/{print $2}' /proc/meminfo)
      ma=$(${awk} '/^MemAvailable:/{print $2}' /proc/meminfo)
      if [ -n "$mt" ] && [ "$mt" -gt 0 ]; then
        usedp=$(( (mt - ma) * 100 / mt ))
        ug=$(${awk} -v t="$mt" -v a="$ma" 'BEGIN{printf "%.1f",(t-a)/1048576}')
        tg=$(${awk} -v t="$mt" 'BEGIN{printf "%.0f",t/1048576}')
        printf '\033[35m󰍛\033[0m  %s \033[90m%sG/%sG\033[0m\n' "$(${bar} "$usedp" 7 35)" "$ug" "$tg"
      fi

      # Root filesystem usage with a primary bar + free space.
      dline=$(${df} -h --output=pcent,avail / 2>/dev/null | ${tail} -n1)
      if [ -n "$dline" ]; then
        dp=$(printf '%s' "$dline" | ${awk} '{gsub(/%/,"",$1);print $1+0}')
        dav=$(printf '%s' "$dline" | ${awk} '{print $2}')
        printf '\033[33m󰋊\033[0m  %s \033[90m%s своб\033[0m\n' "$(${bar} "$dp" 7 33)" "$dav"
      fi

      # Uptime from /proc/uptime (seconds).
      up=$(${cat} /proc/uptime); up=''${up%%.*}
      d=$(( up / 86400 )); hh=$(( up % 86400 / 3600 )); mm=$(( up % 3600 / 60 ))
      u=""; [ "$d" -gt 0 ] && u="''${d}д "
      printf '\033[32m󰅐\033[0m  \033[37m%s%dч %dм\033[0m\n' "$u" "$hh" "$mm"
     } | ${centerTop}
     ${sleep} 5
    done
  '';

  # Hardware pane: output volume and screen brightness, each a coloured bar with
  # its percentage. Volume comes from wireplumber (wpctl); a muted sink shows a
  # crossed-speaker glyph in grey. Brightness comes from brightnessctl -m.
  hwPane = pkgs.writeShellScript "lock-hw" ''
    while :; do
     {
      v=$(${wpctl} get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
      if [ -n "$v" ]; then
        vp=$(printf '%s' "$v" | ${awk} '{print int($2*100+0.5)}'); : "''${vp:=0}"
        if printf '%s' "$v" | ${grep} -q MUTED; then
          printf '\033[90m󰝟\033[0m  %s \033[90m%s%%\033[0m\n' "$(${bar} "$vp" 7 90)" "$vp"
        else
          printf '\033[36m󰕾\033[0m  %s \033[90m%s%%\033[0m\n' "$(${bar} "$vp" 7 36)" "$vp"
        fi
      fi
      bp=$(${brightnessctl} -m 2>/dev/null | ${awk} -F, '{gsub(/%/,"",$4);print $4+0}')
      [ -n "$bp" ] && printf '\033[93m󰃟\033[0m  %s \033[90m%s%%\033[0m\n' "$(${bar} "$bp" 7 93)" "$bp"
     } | ${centerTop}
     ${sleep} 5
    done
  '';

  # Network pane: the active Wi-Fi SSID with coloured signal bars (green = strong
  # → red = weak), and the machine's primary IP. Falls back to a muted "нет сети"
  # when no Wi-Fi link is up; the IP line still shows on wired connections.
  netPane = pkgs.writeShellScript "lock-net" ''
    while :; do
     {
      w=$(${nmcli} -t -f IN-USE,SSID,SIGNAL dev wifi 2>/dev/null \
        | ${awk} -F: '$1=="*"{print $2"|"$3; exit}')
      if [ -n "$w" ]; then
        ssid=''${w%|*}; sig=''${w#*|}; : "''${sig:=0}"
        if   [ "$sig" -ge 75 ]; then g='▂▄▆█'; c=32
        elif [ "$sig" -ge 50 ]; then g='▂▄▆ '; c=93
        elif [ "$sig" -ge 25 ]; then g='▂▄   '; c=93
        else                         g='▂    '; c=31; fi
        [ ''${#ssid} -gt 16 ] && ssid="''${ssid:0:15}…"
        printf '\033[34m󰖩\033[0m  \033[37m%s\033[0m  \033[%dm%s\033[0m\n' "$ssid" "$c" "$g"
      else
        printf '\033[90m󰖪  нет сети\033[0m\n'
      fi
      ipaddr=$(${ip} route get 1.1.1.1 2>/dev/null \
        | ${awk} '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1);exit}}')
      [ -n "$ipaddr" ] && printf '\033[36m󰩟\033[0m  \033[90m%s\033[0m\n' "$ipaddr"
      # VPN / tunnel: show the interface name (green shield) only when a tunnel
      # link is actually up, so it never reports a connection that isn't there.
      vpnif=$(${ip} -o link show up 2>/dev/null \
        | ${awk} -F': ' '$2 ~ /^(tun|wg|amnezia|proton|nordlynx)/{print $2; exit}')
      [ -n "$vpnif" ] && printf '\033[32m󰦝\033[0m  \033[32mVPN\033[0m \033[90m%s\033[0m\n' "$vpnif"
     } | ${centerTop}
     ${sleep} 10
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

  # Header pane: a time-of-day greeting, who, and when — three coloured lines so
  # the top of the column opens with colour rather than flat grey. The greeting
  # (violet, with a matching sun/moon glyph) changes through the day; user@host
  # sits below in tide/muted, and the weekday/date in amber. Refreshed once a
  # minute (the greeting and date only change slowly; cheap enough). centerTop
  # strips the SGR codes when measuring width, so colouring never skews centring.
  headerPane = pkgs.writeShellScript "lock-header" ''
    user=$(${id} -un 2>/dev/null)
    host=$(${uname} -n 2>/dev/null)
    while :; do
      h=$(${date} +%H)
      if   [ "$h" -lt 5 ];  then greet='󰖔 Доброй ночи'
      elif [ "$h" -lt 12 ]; then greet='󰖜 Доброе утро'
      elif [ "$h" -lt 18 ]; then greet='󰖙 Добрый день'
      else                       greet='󰖛 Добрый вечер'
      fi
      {
        printf '\033[1;35m%s\033[0m\n' "$greet"
        printf '\033[34m󰀄 %s\033[0m\033[90m@%s\033[0m\n' "$user" "$host"
        printf '\033[93m󰃭 %s\033[0m\n' "$(${date} '+%a, %d %b')"
      } | ${centerTop}
      ${sleep} 60
    done
  '';

  # Console password feedback. swaylock-plugin holds the keyboard grab, so this
  # pane can never see individual keystrokes — there is no live, per-character
  # echo (that is physically impossible here). Instead the pam_exec hook (see
  # modules/desktop/niri.nix) appends "<epoch> <len>" to the state file below on
  # every password *submit*, and we render, in the lock's own console style:
  #   • at rest        →  a quiet "❯ Введите пароль" prompt (awaiting input)
  #   • on submit      →  "●●●●  Проверка…"  (length-only mask + verifying)
  #   • ~1s later      →  "✗ Неверно · попытка N"
  # The "wrong" inference is sound: a correct password tears the lock surface
  # down within that second, so any attempt this pane still shows was a failure.
  # The pam hook records only the password's length, never the password.
  feedbackPane = pkgs.writeShellScript "lock-feedback" ''
    f="/run/user/$(${id} -u)/lock-feedback"
    seen=0; state=rest; attempt=0; masklen=0; marked=0; ts=0
    render() {
      w=$(${tmux} display -p '#{pane_width}' 2>/dev/null); : "''${w:=0}"
      case "$state" in
        rest)  line=$'\033[90m❯ Введите пароль\033[0m' ;;
        check) m=$(${awk} -v n="$masklen" 'BEGIN{s="";for(i=0;i<n;i++)s=s"●";print s}')
               line=$'\033[33m'"$m  Проверка…"$'\033[0m' ;;
        wrong) line=$'\033[31m'"✗ Неверно · попытка $attempt"$'\033[0m' ;;
      esac
      vis=$(printf '%s' "$line" | ${sed} 's/\x1b\[[0-9;]*m//g')
      pad=$(( (w - ''${#vis}) / 2 )); [ "$pad" -lt 0 ] && pad=0
      printf '\033[H\033[2J%*s%s' "$pad" "" "$line"
    }
    printf '\033[?25l'
    render
    while :; do
      if [ -r "$f" ]; then
        n=$(${wc} -l < "$f" 2>/dev/null); : "''${n:=0}"
        if [ "$n" -gt "$seen" ]; then
          masklen=$(${tail} -n1 "$f" | ${awk} '{print $2+0}')
          [ "$masklen" -gt 24 ] && masklen=24
          seen=$n; attempt=$n; state=check; marked=0; ts=$(${date} +%s); render
        fi
      fi
      if [ "$state" = check ] && [ "$marked" -eq 0 ]; then
        now=$(${date} +%s)
        [ "$(( now - ts ))" -ge 1 ] && { state=wrong; marked=1; render; }
      fi
      ${sleep} 0.3
    done
  '';

  # Builds the tmux layout: a wide activity animation on the left and a narrow
  # ~19% right column. The column is a *compact* top-anchored stack — the
  # notifications trail owns the column, then fixed-height widgets are inserted
  # ABOVE it (`-b`) top→bottom as header, clock, feedback, calendar, status,
  # hardware, system, network, so the widgets form one tight block at the top
  # (each sized to its content, no centring gaps) and the notifications trail
  # fills whatever is left to the bottom edge. Then it attaches so the terminal
  # renders it. The (transparent) unlock indicator is drawn by swaylock on top,
  # nothing overlaid.
  lockLayout = pkgs.writeShellScript "lock-layout" ''
    T="${tmux} -L screenlock -f ${lockTmuxConf}"
    $T kill-server 2>/dev/null || true
    # Each split is targeted at an explicit pane id (captured with -P), so the
    # layout never depends on which pane tmux happens to leave "active". The
    # right column starts as the notifications pane; `-b -l N` inserts each fixed
    # widget directly ABOVE it with an absolute height of N rows (header 3,
    # clock 3, feedback 3, current-month calendar 8, status 3, hardware 2,
    # system 5, network 3), leaving the rest to notifications.
    left=$($T   new-session   -d    -P -F '#{pane_id}' -s lock       "${activity}")
    notifs=$($T split-window -h     -P -F '#{pane_id}' -t "$left"    -l 19% "${notifsPane}")
    $T          split-window -v -b                     -t "$notifs"  -l 3   "${headerPane}"
    $T          split-window -v -b                     -t "$notifs"  -l 3   "${clockPane}"
    $T          split-window -v -b                     -t "$notifs"  -l 3   "${feedbackPane}"
    $T          split-window -v -b                     -t "$notifs"  -l 8   "${calPane}"
    $T          split-window -v -b                     -t "$notifs"  -l 3   "${statusPane}"
    $T          split-window -v -b                     -t "$notifs"  -l 2   "${hwPane}"
    $T          split-window -v -b                     -t "$notifs"  -l 5   "${sysPane}"
    $T          split-window -v -b                     -t "$notifs"  -l 3   "${netPane}"
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

    # Start each lock with an empty feedback log. The pam_exec hook (see
    # modules/desktop/niri.nix) appends one "<epoch> <len>" line per password
    # submit; the feedback pane renders the mask / failed-attempt counter from
    # it. Truncating here resets the attempt count for every new lock session.
    : > "/run/user/$(${id} -u)/lock-feedback" 2>/dev/null || true

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

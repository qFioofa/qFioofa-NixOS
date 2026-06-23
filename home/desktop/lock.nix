{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme) bg bgSurface fg fgMuted primary success warning error violet tide coral font;
  strip = c: builtins.substring 1 (builtins.stringLength c) c;

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

  sh = file: vars: builtins.readFile (pkgs.replaceVars (./scripts/lock + "/${file}") vars);

  alacrittyConf = pkgs.replaceVars ./themes/lock/alacritty.toml {
    inherit font bg fg bgSurface error success primary tide violet fgMuted coral warning;
  };
  lockTmuxConf = pkgs.replaceVars ./themes/lock/tmux.conf { inherit bgSurface; };

  bar = pkgs.writeShellScript "lock-bar" (sh "bar.sh" { inherit awk; });
  activity = pkgs.writeShellScript "lock-activity"
    (sh "activity.sh" { inherit od asciiquarium cbonsai cmatrix lavat pipes; });
  clockPane = pkgs.writeShellScript "lock-clock" (sh "clock.sh" { inherit tmux date sed sleep; });
  center = pkgs.writeShellScript "lock-center" (sh "center.sh" { inherit tmux cat wc sed awk; });
  centerTop = pkgs.writeShellScript "lock-center-top" (sh "center-top.sh" { inherit tmux cat sed awk; });
  calPane = pkgs.writeShellScript "lock-cal" (sh "cal.sh" {
    inherit cal awk sleep;
    centerTop = "${centerTop}";
  });
  statusPane = pkgs.writeShellScript "lock-status" (sh "status.sh" {
    inherit cat playerctl sleep;
    centerTop = "${centerTop}";
  });
  sysPane = pkgs.writeShellScript "lock-sys" (sh "sys.sh" {
    inherit cat awk df tail sleep;
    bar = "${bar}";
    centerTop = "${centerTop}";
  });
  hwPane = pkgs.writeShellScript "lock-hw" (sh "hw.sh" {
    inherit wpctl awk grep brightnessctl sleep;
    bar = "${bar}";
    centerTop = "${centerTop}";
  });
  netPane = pkgs.writeShellScript "lock-net" (sh "net.sh" {
    inherit nmcli awk ip sleep;
    centerTop = "${centerTop}";
  });
  notifsPane = pkgs.writeShellScript "lock-notifs"
    (sh "notifs.sh" { inherit tmux swayncClient dbusMonitor awk; });
  headerPane = pkgs.writeShellScript "lock-header" (sh "header.sh" {
    inherit id uname date sleep;
    centerTop = "${centerTop}";
  });
  feedbackPane = pkgs.writeShellScript "lock-feedback"
    (sh "feedback.sh" { inherit id tmux awk sed wc tail date sleep; });

  lockLayout = pkgs.writeShellScript "lock-layout" (sh "layout.sh" {
    inherit tmux;
    lockTmuxConf = "${lockTmuxConf}";
    activity = "${activity}";
    notifsPane = "${notifsPane}";
    headerPane = "${headerPane}";
    clockPane = "${clockPane}";
    feedbackPane = "${feedbackPane}";
    calPane = "${calPane}";
    statusPane = "${statusPane}";
    hwPane = "${hwPane}";
    sysPane = "${sysPane}";
    netPane = "${netPane}";
  });
  lockBackground = pkgs.writeShellScript "lock-background" (sh "background.sh" {
    inherit windowtolayer alacritty;
    alacrittyConf = "${alacrittyConf}";
    lockLayout = "${lockLayout}";
  });

  transparent = "00000000";
  swaylockColors = builtins.concatStringsSep " " [
    "--color ${strip bg}"
    "--inside-color ${transparent}"
    "--inside-ver-color ${transparent}"
    "--inside-wrong-color ${transparent}"
    "--inside-clear-color ${transparent}"
    "--ring-color ${transparent}"
    "--ring-ver-color ${transparent}"
    "--ring-wrong-color ${transparent}"
    "--ring-clear-color ${transparent}"
    "--key-hl-color ${transparent}"
    "--bs-hl-color ${transparent}"
    "--text-color ${transparent}"
    "--text-ver-color ${transparent}"
    "--text-wrong-color ${transparent}"
    "--text-clear-color ${transparent}"
    "--line-color ${transparent}"
    "--separator-color ${transparent}"
    "--layout-bg-color ${transparent}"
    "--layout-text-color ${transparent}"
    "--layout-border-color ${transparent}"
  ];

  lockBin = pkgs.writeShellScriptBin "lock" (sh "lock.sh" {
    inherit flock id swaylock font;
    swaylockColors = swaylockColors;
    lockBackground = "${lockBackground}";
  });

  # Persist the backlight level, but only while the screen is actually lit.
  # During an idle suspend the monitors have already been DPMS-powered-off (see
  # the 360s listener below), which drops intel_backlight to 0, so a plain
  # `brightnessctl --save` at suspend time would capture 0 and the matching
  # restore would black the screen on resume. Skip any non-positive reading and
  # keep the last good value instead.
  saveBrightness = pkgs.writeShellScript "lock-save-brightness" ''
    cur=$(${brightnessctl} get)
    if [ "''${cur:-0}" -gt 0 ]; then
      printf '%s' "$cur" > "$XDG_RUNTIME_DIR/lock-brightness"
    fi
  '';
  restoreBrightness = pkgs.writeShellScript "lock-restore-brightness" ''
    val=$(${cat} "$XDG_RUNTIME_DIR/lock-brightness" 2>/dev/null || true)
    if [ "''${val:-0}" -gt 0 ]; then
      ${brightnessctl} set "$val"
    fi
  '';
in
{
  home.packages = [ lockBin ];

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${lockBin}/bin/lock";
        # Snapshot the backlight level just before sleep and put it back on
        # resume, so suspending never leaves the screen dimmed (some laptops
        # reset the backlight to minimum across suspend). saveBrightness refuses
        # to persist a 0 reading, so an idle suspend — where the monitors are
        # already DPMS-off — falls back to the good value captured at lock time.
        before_sleep_cmd = "${pkgs.writeShellScript "lock-before-sleep" ''
          ${saveBrightness}
          exec ${lockBin}/bin/lock
        ''}";
        after_sleep_cmd = "${pkgs.writeShellScript "after-sleep-restore" ''
          niri msg action power-on-monitors
          ${restoreBrightness}
        ''}";
      };
      # Timeouts are cumulative from the last input, so each step counts from
      # boot/activity, not from the previous listener.
      listener = [
        {
          # 5 min idle → lock the session. Snapshot the backlight here, while
          # the screen is still lit, so the value is available to restore even
          # though the later power-off/suspend steps drop it to 0.
          timeout = 300;
          on-timeout = "${pkgs.writeShellScript "lock-on-idle" ''
            ${saveBrightness}
            exec ${lockBin}/bin/lock
          ''}";
        }
        {
          # 1 min into the lock → blank the outputs. The lock's animated
          # dashboard renders fullscreen, so the backlight and GPU compositing
          # are its real power draw; powering the monitors off stops both while
          # the session stays locked. Any input wakes them straight back on, and
          # restoreBrightness undoes the 0 the DPMS-off left behind.
          timeout = 360;
          on-timeout = "niri msg action power-off-monitors";
          on-resume = "${pkgs.writeShellScript "lock-power-on" ''
            niri msg action power-on-monitors
            ${restoreBrightness}
          ''}";
        }
        {
          timeout = 900; # 10 min into the lock (15 min idle) → suspend.
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}

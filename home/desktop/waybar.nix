{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme)
    bg bgSurface fg fgDim fgMuted
    primary success warning error
    violet tide amber coral;

  playerctl = "${pkgs.playerctl}/bin/playerctl";

  # niri-taskbar: a native (CFFI/GTK) Waybar module for niri that renders the
  # real application icons from each window's desktop entry — something a text
  # custom module cannot do. Pinned to the release matching the installed niri
  # (v25.08); the IPC protocol must line up with the running compositor.
  niriTaskbar = pkgs.rustPlatform.buildRustPackage rec {
    pname = "niri-taskbar";
    version = "0.3.0+niri.25.08";
    src = pkgs.fetchFromGitHub {
      owner = "LawnGnome";
      repo = "niri-taskbar";
      rev = "v0.3.0+niri.25.08";
      hash = "sha256-Gbzh4OTkvtP9F/bfDUyA14NH2DMDdr3i6oFoFwinEAg=";
    };
    cargoHash = "sha256-Ql9iqbbS3DY7o5/PR96c2t4VXKoS1kjZ9k3SfhNdbzE=";
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.gtk3 ];

    # Upstream shows every window on the monitor (all workspaces). Restrict the
    # snapshot to windows on the *active* workspace of each output, so the bar
    # only lists apps on the current workspace. The snapshot is already sorted by
    # workspace index → column position, so within the workspace icons stay in
    # on-screen order and reshuffle when a window is moved left/right.
    postPatch = ''
      substituteInPlace src/niri/state.rs \
        --replace-fail \
          'return Some(WindowWorkspace { window, workspace });' \
          'if workspace.is_active { return Some(WindowWorkspace { window, workspace }); }'
    '';
  };
  niriTaskbarLib = "${niriTaskbar}/lib/libniri_taskbar.so";

  # Now-playing indicator. Always prints valid JSON so the capsule renders
  # something graceful ("Idle") when no player is active.
  nowPlaying = pkgs.writeShellScript "waybar-nowplaying" ''
    esc() { printf '%s' "$1" | ${pkgs.gnused}/bin/sed 's/\\/\\\\/g; s/"/\\"/g'; }

    status=$(${playerctl} status 2>/dev/null)
    if [ -z "$status" ]; then
      printf '{"text":"󰝛  Idle · no sound","tooltip":"Nothing is playing","class":"empty"}\n'
      exit 0
    fi

    title=$(${playerctl} metadata title 2>/dev/null)
    artist=$(${playerctl} metadata artist 2>/dev/null)
    [ -z "$title" ] && title="Unknown"

    if [ ''${#title} -gt 28 ]; then
      title=$(printf '%s' "$title" | ${pkgs.coreutils}/bin/cut -c1-27)…
    fi

    case "$status" in
      Playing) icon="󰎆" ; cls="playing" ;;
      Paused)  icon="󰏤" ; cls="paused"  ;;
      *)       icon="󰎈" ; cls="stopped" ;;
    esac

    printf '{"text":"%s  %s","tooltip":"%s","class":"%s"}\n' \
      "$icon" "$(esc "$title")" "$(esc "$artist")" "$cls"
  '';
in
{
  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 36;
      spacing = 0;
      margin-top = 6;
      margin-left = 8;
      margin-right = 8;

      modules-left = [ "group/left-a" "group/left-b" "group/left-c" ];
      modules-center = [ "group/center-a" "group/center-b" ];
      modules-right = [ "group/right-a" "group/right-b" ];

      "group/left-a" = {
        orientation = "horizontal";
        modules = [ "clock" "niri/language" ];
      };
      "group/left-b" = {
        orientation = "horizontal";
        modules = [ "niri/workspaces" ];
      };
      # Media capsule: now-playing block + sound controls live together.
      "group/left-c" = {
        orientation = "horizontal";
        modules = [ "custom/player" "group/audio" ];
      };
      # Volume icon in the bar; the slider slides out on hover.
      "group/audio" = {
        orientation = "horizontal";
        drawer = {
          transition-duration = 300;
          transition-left-to-right = true;
          children-class = "drawer-child";
        };
        modules = [ "pulseaudio" "pulseaudio/slider" ];
      };

      "group/center-a" = {
        orientation = "horizontal";
        modules = [ "tray" ];
      };
      # Taskbar of open windows, sitting to the right of the tray. niri-taskbar
      # renders real app icons (per output, ordered by workspace then open time).
      "group/center-b" = {
        orientation = "horizontal";
        modules = [ "cffi/niri-taskbar" ];
      };

      # Hardware controls: brightness drawer + idle inhibitor.
      "group/right-a" = {
        orientation = "horizontal";
        modules = [ "group/brightness" "idle_inhibitor" ];
      };
      # Brightness icon in the bar; the slider slides out on hover.
      "group/brightness" = {
        orientation = "horizontal";
        drawer = {
          transition-duration = 300;
          transition-left-to-right = true;
          children-class = "drawer-child";
        };
        modules = [ "backlight" "backlight/slider" ];
      };
      # Status + system capsule.
      "group/right-b" = {
        orientation = "horizontal";
        modules = [ "network" "bluetooth" "battery" "custom/swaync" "custom/power" ];
      };

      clock = {
        format = "󰥔  {:%H:%M}";
        format-alt = "󰃭  {:%a %d %b %Y}";
        tooltip-format = "<tt>{calendar}</tt>";
        on-click = "swaync-client -t -sw";
        calendar = {
          mode = "month";
          weeks-pos = "left";
          format = {
            today = "<span color='${primary}'><b>{}</b></span>";
          };
        };
      };

      "custom/swaync" = {
        tooltip = false;
        format = "{icon}";
        format-icons = {
          notification = "<span foreground='${error}'>󰂞</span>";
          none = "󰂚";
          dnd-notification = "<span foreground='${error}'>󰂠</span>";
          dnd-none = "󰂛";
          inhibited-notification = "<span foreground='${error}'>󰂞</span>";
          inhibited-none = "󰂚";
          dnd-inhibited-notification = "<span foreground='${error}'>󰂠</span>";
          dnd-inhibited-none = "󰂛";
        };
        return-type = "json";
        exec-if = "which swaync-client";
        exec = "swaync-client -swb";
        on-click = "swaync-client -t -sw";
        on-click-right = "swaync-client -d -sw";
        escape = true;
      };

      "custom/power" = {
        tooltip = false;
        format = "󰐥";
        on-click = "powermenu";
      };

      # Now-playing block — click toggles play/pause, scroll changes track.
      "custom/player" = {
        return-type = "json";
        exec = "${nowPlaying}";
        interval = 2;
        format = "{}";
        escape = true;
        on-click = "${playerctl} play-pause";
        on-click-right = "${playerctl} next";
        on-scroll-up = "${playerctl} next";
        on-scroll-down = "${playerctl} previous";
      };

      # Native niri taskbar (CFFI module) — real app icons, click to focus.
      "cffi/niri-taskbar" = {
        module_path = niriTaskbarLib;
      };

      "niri/language" = {
        format = "󰌌  {short}";
        tooltip-format = "{long}";
        on-click = "layout-popup";
      };

      "niri/workspaces" = {
        format = "{index}";
        on-click = "activate";
      };

      tray = {
        spacing = 8;
        icon-size = 18;
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "󰅶";
          deactivated = "󰾪";
        };
        tooltip-format-activated = "Idle inhibitor: on";
        tooltip-format-deactivated = "Idle inhibitor: off";
      };

      network = {
        format-wifi = "󰤨  {essid} ({signalStrength}%)";
        format-ethernet = "󰈀  {ifname}";
        format-disconnected = "󰤭  off";
        tooltip-format-wifi = "{ipaddr}/{cidr}\n{signaldBm}dBm @ {frequency}GHz";
        tooltip-format-ethernet = "{ipaddr}/{cidr}";
        max-length = 24;
        on-click = "wifi-popup";
        on-click-right = "nm-connection-editor";
      };

      bluetooth = {
        format = "󰂯";
        format-disabled = "󰂲";
        format-off = "󰂲";
        format-connected = "󰂱  {num_connections}";
        tooltip-format = "{controller_alias}\t{controller_address}";
        tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
        on-click = "bt-popup";
        on-click-right = "blueman-manager";
      };

      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon}  {capacity}%";
        format-charging = "󰂄  {capacity}%";
        format-plugged = "󰂄  {capacity}%";
        format-full = "󰁹  Full";
        format-icons = [ "󰁻" "󰁽" "󰁿" "󰂁" "󰁹" ];
        tooltip-format = "{timeTo} ({power:.1f}W)";
      };

      pulseaudio = {
        format = "{icon}  {volume}%";
        format-muted = "󰝟  muted";
        format-icons = {
          default = [ "󰕿" "󰖀" "󰕾" ];
        };
        on-scroll-up = "swayosd-client --output-volume raise";
        on-scroll-down = "swayosd-client --output-volume lower";
        on-click = "swayosd-client --output-volume mute-toggle";
        on-click-right = "pavucontrol";
      };

      "pulseaudio/slider" = {
        min = 0;
        max = 100;
        orientation = "horizontal";
      };

      backlight = {
        format = "󰃠  {percent}%";
        tooltip-format = "Brightness: {percent}%";
        on-scroll-up = "swayosd-client --brightness raise";
        on-scroll-down = "swayosd-client --brightness lower";
      };

      "backlight/slider" = {
        min = 0;
        max = 100;
        orientation = "horizontal";
      };
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        color: ${fg};
      }

      tooltip {
        background: ${bg};
        border: 1px solid ${bgSurface};
        border-radius: 8px;
        color: ${fg};
        padding: 4px 8px;
      }

      #left-a,
      #left-b,
      #left-c,
      #center-a,
      #center-b,
      #right-a,
      #right-b {
        background: rgba(21, 21, 21, 0.92);
        border: 1px solid ${bgSurface};
        border-radius: 12px;
        padding: 0 6px;
      }

      #left-a { margin-right: 6px; }
      #left-b { margin-right: 6px; }
      #left-c { margin-right: 6px; }
      #center-a { margin-right: 6px; }
      #right-a { margin-right: 6px; }

      /* Collapse the tray / taskbar capsules when they are empty. */
      #center-a.empty,
      #center-b.empty {
        background: transparent;
        border-color: transparent;
        padding: 0;
        margin: 0;
      }

      #clock {
        padding: 0 10px;
        color: ${fg};
        font-weight: bold;
      }

      #language {
        padding: 0 10px;
        margin: 6px 0;
        border-left: 1px solid ${bgSurface};
        color: ${tide};
        font-weight: bold;
        transition: color 0.2s ease;
      }

      #language:hover {
        color: ${fg};
      }

      #custom-swaync {
        padding: 0 10px;
        margin: 6px 0;
        border-left: 1px solid ${bgSurface};
        color: ${fgDim};
        transition: color 0.2s ease;
      }

      #custom-swaync:hover {
        color: ${fg};
      }

      #custom-power {
        padding: 0 12px 0 10px;
        margin: 6px 0;
        border-left: 1px solid ${bgSurface};
        color: ${fgDim};
        transition: color 0.2s ease;
      }

      #custom-power:hover {
        color: ${error};
      }

      #workspaces button {
        padding: 0 8px;
        color: ${fgMuted};
        border: none;
        border-radius: 8px;
        background: transparent;
        margin: 4px 2px;
        transition: all 0.2s ease;
      }

      #workspaces button.active {
        color: ${primary};
        background: rgba(255, 190, 137, 0.12);
      }

      #workspaces button:hover {
        background: ${bgSurface};
        color: ${fg};
      }

      #tray {
        padding: 0 8px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }

      /* niri-taskbar: real app icons. .focused marks the active window. */
      .niri-taskbar {
        padding: 0 4px;
      }

      .niri-taskbar button {
        padding: 0 6px;
        margin: 3px 2px;
        border-radius: 8px;
        background: transparent;
        transition: all 0.2s ease;
      }

      .niri-taskbar button.focused {
        background: rgba(255, 190, 137, 0.12);
      }

      .niri-taskbar button:hover {
        background: ${bgSurface};
      }

      .niri-taskbar button.urgent {
        background: rgba(245, 122, 122, 0.18);
      }

      /* Now-playing block; divider separates it from the sound controls. */
      #custom-player {
        padding: 0 10px;
        margin: 6px 0;
        border-right: 1px solid ${bgSurface};
        color: ${coral};
      }

      #custom-player.empty {
        color: ${fgMuted};
      }

      #idle_inhibitor {
        padding: 0 10px;
        margin: 6px 0;
        border-left: 1px solid ${bgSurface};
        color: ${fgMuted};
      }

      #idle_inhibitor.activated {
        color: ${primary};
      }

      #network,
      #bluetooth,
      #battery,
      #pulseaudio,
      #backlight {
        padding: 0 10px;
      }

      /* Dividers between the status/system modules. */
      #bluetooth,
      #battery {
        margin: 6px 0;
        border-left: 1px solid ${bgSurface};
      }

      #network { color: ${tide}; }
      #network.disconnected { color: ${fgMuted}; }

      #bluetooth { color: ${tide}; }
      #bluetooth.disabled,
      #bluetooth.off { color: ${fgMuted}; }
      #bluetooth.connected { color: ${primary}; }

      #battery { color: ${success}; }
      #battery.charging { color: ${success}; }
      #battery.warning:not(.charging) { color: ${warning}; }
      #battery.critical:not(.charging) {
        color: ${error};
        animation: blink 1s steps(2) infinite;
      }

      @keyframes blink {
        to { color: transparent; }
      }

      #pulseaudio { color: ${violet}; }
      #pulseaudio.muted { color: ${fgMuted}; }

      #backlight { color: ${amber}; }

      /* Sliders for audio and brightness. */
      #pulseaudio-slider,
      #backlight-slider {
        min-width: 84px;
        padding: 0 12px;
      }

      #pulseaudio-slider trough,
      #backlight-slider trough {
        min-width: 84px;
        min-height: 6px;
        border-radius: 999px;
        background-color: ${bgSurface};
      }

      #pulseaudio-slider highlight {
        background-color: ${violet};
        border-radius: 999px;
      }

      #backlight-slider highlight {
        background-color: ${amber};
        border-radius: 999px;
      }

      #pulseaudio-slider slider,
      #backlight-slider slider {
        background-color: ${fg};
        border-radius: 999px;
        min-width: 12px;
        min-height: 12px;
        margin: -4px 0;
      }
    '';
  };
}

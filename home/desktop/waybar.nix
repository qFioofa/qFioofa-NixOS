{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme)
    bg bgSurface fg fgDim fgMuted
    primary success warning error
    violet tide amber coral;
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

      modules-left = [ "group/left-a" "group/left-b" ];
      modules-center = [ "group/center-a" "group/center-b" ];
      modules-right = [ "group/right-a" "group/right-b" ];

      "group/left-a" = {
        orientation = "horizontal";
        modules = [ "clock" "custom/swaync" ];
      };
      "group/left-b" = {
        orientation = "horizontal";
        modules = [ "niri/workspaces" ];
      };

      "group/center-a" = {
        orientation = "horizontal";
        modules = [ "tray" ];
      };
      "group/center-b" = {
        orientation = "horizontal";
        modules = [ "wlr/taskbar" ];
      };

      "group/right-a" = {
        orientation = "horizontal";
        modules = [ "mpris" "idle_inhibitor" ];
      };
      "group/right-b" = {
        orientation = "horizontal";
        modules = [ "network" "bluetooth" "battery" "pulseaudio" "backlight" ];
      };

      clock = {
        format = "  {:%H:%M}";
        format-alt = "  {:%a %d %b %Y}";
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
          notification = "<span foreground='${error}'><sup></sup></span>";
          none = "";
          dnd-notification = "<span foreground='${error}'><sup></sup></span>";
          dnd-none = "";
          inhibited-notification = "<span foreground='${error}'><sup></sup></span>";
          inhibited-none = "";
          dnd-inhibited-notification = "<span foreground='${error}'><sup></sup></span>";
          dnd-inhibited-none = "";
        };
        return-type = "json";
        exec-if = "which swaync-client";
        exec = "swaync-client -swb";
        on-click = "swaync-client -t -sw";
        on-click-right = "swaync-client -d -sw";
        escape = true;
      };

      "niri/workspaces" = {
        format = "{index}";
        on-click = "activate";
      };

      tray = {
        spacing = 8;
        icon-size = 18;
      };

      "wlr/taskbar" = {
        format = "{icon}";
        icon-size = 18;
        tooltip-format = "{title}";
        on-click = "activate";
        on-click-middle = "close";
        on-click-right = "minimize";
        ignore-list = [ ];
      };

      mpris = {
        format = "{player_icon}  {title}";
        format-paused = "{player_icon}  <i>{title}</i>";
        player-icons = {
          default = "";
          firefox = "";
        };
        title-len = 25;
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "";
          deactivated = "";
        };
        tooltip-format-activated = "Idle inhibitor: on";
        tooltip-format-deactivated = "Idle inhibitor: off";
      };

      network = {
        format-wifi = "  {essid} ({signalStrength}%)";
        format-ethernet = "  {ifname}";
        format-disconnected = "  off";
        tooltip-format-wifi = "{ipaddr}/{cidr}\n{signaldBm}dBm @ {frequency}GHz";
        tooltip-format-ethernet = "{ipaddr}/{cidr}";
        max-length = 24;
        on-click = "nm-connection-editor";
      };

      bluetooth = {
        format = "";
        format-disabled = "";
        format-off = "";
        format-connected = "  {num_connections}";
        tooltip-format = "{controller_alias}\t{controller_address}";
        tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
        on-click = "blueman-manager";
      };

      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon}  {capacity}%";
        format-charging = "  {capacity}%";
        format-plugged = "  {capacity}%";
        format-full = "  Full";
        format-icons = [ "" "" "" "" "" ];
        tooltip-format = "{timeTo} ({power:.1f}W)";
      };

      pulseaudio = {
        format = "{icon}  {volume}%";
        format-muted = "  muted";
        format-icons = {
          default = [ "" "" "" ];
        };
        on-scroll-up = "swayosd-client --output-volume raise";
        on-scroll-down = "swayosd-client --output-volume lower";
        on-click = "swayosd-client --output-volume mute-toggle";
        on-click-right = "pavucontrol";
      };

      backlight = {
        format = "  {percent}%";
        tooltip-format = "Brightness: {percent}%";
        on-scroll-up = "swayosd-client --brightness raise";
        on-scroll-down = "swayosd-client --brightness lower";
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
      #center-a { margin-right: 6px; }
      #right-a { margin-right: 6px; }

      #center-a.empty,
      #center-b.empty,
      #right-a.empty {
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

      #custom-swaync {
        padding: 0 10px 0 4px;
        color: ${fgDim};
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

      #taskbar button {
        padding: 0 6px;
        margin: 3px 2px;
        border-radius: 8px;
        background: transparent;
        transition: all 0.2s ease;
      }

      #taskbar button.active {
        background: rgba(255, 190, 137, 0.12);
      }

      #taskbar button:hover {
        background: ${bgSurface};
      }

      #mpris {
        padding: 0 10px;
        color: ${coral};
      }

      #idle_inhibitor {
        padding: 0 8px;
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
    '';
  };
}

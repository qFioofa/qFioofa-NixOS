{ pkgs, ... }:
let
  # yugen-ash palette
  bg = "#151515";
  bgSurface = "#303030";
  fg = "#D4D4D4";
  fgDim = "#A9A9A9";
  fgMuted = "#696969";
  primary = "#FFBE89";
  success = "#7EAB8E";
  warning = "#FFF2AF";
  error = "#F57A7A";
  violet = "#c678dd";
  tide = "#79a0aa";
  amber = "#D4A76A";
  coral = "#FF9E8B";
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

      modules-left = [
        "niri/workspaces"
        "niri/window"
      ];
      modules-center = [
        "clock"
      ];
      modules-right = [
        "mpris"
        "idle_inhibitor"
        "backlight"
        "pulseaudio"
        "network"
        "battery"
        "tray"
      ];

      "niri/workspaces" = {
        format = "{icon}";
        format-icons = {
          active = "";
          default = "";
        };
      };

      "niri/window" = {
        format = "{}";
        max-length = 40;
        rewrite = {
          "" = "";
        };
      };

      clock = {
        format = "  {:%H:%M}";
        format-alt = "  {:%a %d %b %Y}";
        tooltip-format = "<tt>{calendar}</tt>";
        calendar = {
          mode = "month";
          weeks-pos = "left";
          format = {
            today = "<span color='${primary}'><b>{}</b></span>";
          };
        };
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

      backlight = {
        format = "  {percent}%";
        tooltip-format = "Brightness: {percent}%";
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

      network = {
        format-wifi = "  {essid} ({signalStrength}%)";
        format-ethernet = "  {ifname}";
        format-disconnected = "  off";
        tooltip-format-wifi = "{ipaddr}/{cidr}\n{signaldBm}dBm @ {frequency}GHz";
        tooltip-format-ethernet = "{ipaddr}/{cidr}";
        max-length = 24;
        on-click = "nm-connection-editor";
      };

      pulseaudio = {
        format = "{icon}  {volume}%";
        format-muted = "  muted";
        format-icons = {
          default = [ "" "" "" ];
        };
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-click-right = "pavucontrol";
        scroll-step = 2;
      };

      tray = {
        spacing = 8;
        icon-size = 18;
      };
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(21, 21, 21, 0.92);
        color: ${fg};
        border-radius: 12px;
        border: 1px solid ${bgSurface};
      }

      window#waybar.empty #window {
        padding: 0;
        margin: 0;
      }

      tooltip {
        background: ${bg};
        border: 1px solid ${bgSurface};
        border-radius: 8px;
        color: ${fg};
        padding: 4px 8px;
      }

      #workspaces {
        margin-left: 4px;
      }

      #workspaces button {
        padding: 0 6px;
        color: ${fgMuted};
        border: none;
        border-radius: 6px;
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

      #window {
        padding: 0 12px;
        color: ${fgDim};
      }

      #clock {
        color: ${fg};
        font-weight: bold;
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

      #backlight {
        padding: 0 10px;
        color: ${amber};
      }

      #battery,
      #network,
      #pulseaudio,
      #tray {
        padding: 0 10px;
      }

      #battery {
        color: ${success};
      }

      #battery.charging {
        color: ${success};
      }

      #battery.warning:not(.charging) {
        color: ${warning};
      }

      #battery.critical:not(.charging) {
        color: ${error};
        animation: blink 1s steps(2) infinite;
      }

      @keyframes blink {
        to { color: transparent; }
      }

      #network {
        color: ${tide};
      }

      #network.disconnected {
        color: ${fgMuted};
      }

      #pulseaudio {
        color: ${violet};
      }

      #pulseaudio.muted {
        color: ${fgMuted};
      }

      #tray {
        margin-right: 4px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }
    '';
  };
}

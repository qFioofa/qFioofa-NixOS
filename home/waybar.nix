{ ... }:
{
  programs.waybar = {
    enable = true;
    systemd.enable = false;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;

      modules-left = [ "niri/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];

      clock.format = "{:%a %d %b  %H:%M}";

      battery = {
        format = "{capacity}% {icon}";
        format-icons = [ "" "" "" "" "" ];
        states = { warning = 30; critical = 15; };
      };

      network = {
        format-wifi = "{essid} ";
        format-ethernet = "wired ";
        format-disconnected = "off ";
      };

      pulseaudio = {
        format = "{volume}% {icon}";
        format-muted = "muted ";
        format-icons.default = [ "" "" "" ];
        on-click = "pavucontrol";
      };
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
      }
      window#waybar {
        background: #1e1e2e;
        color: #cdd6f4;
      }
      #workspaces button { padding: 0 8px; color: #cdd6f4; }
      #workspaces button.active { background: #7aa2f7; color: #1e1e2e; }
      #clock, #battery, #network, #pulseaudio, #tray { padding: 0 10px; }
    '';
  };
}

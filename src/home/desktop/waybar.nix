{ ... }: {
  programs.waybar = {
    enable         = true;
    systemd.enable = true;

    settings.mainBar = {
      layer    = "top";
      position = "top";
      height   = 34;

      modules-left   = [ "niri/workspaces" ];
      modules-center = [ "clock" ];
      modules-right  = [ "pulseaudio" "network" "cpu" "memory" "battery" "tray" ];

      "niri/workspaces" = {
        on-click      = "activate";
        format        = "{icon}";
        format-icons  = {
          active  = "󰮯";
          default = "󰊠";
        };
      };

      clock = {
        format     = " {:%H:%M}";
        format-alt = " {:%d %b %Y}";
      };

      cpu    = { format = " {usage}%"; interval = 3; };
      memory = { format = " {}%";     interval = 5; };

      network = {
        format-wifi        = " {essid}";
        format-ethernet    = "󰈀 {ifname}";
        format-disconnected = "󰌙";
      };

      pulseaudio = {
        format       = "{icon} {volume}%";
        format-muted = "󰝟";
        format-icons = { default = [ "󰕿" "󰖀" "󰕾" ]; };
        on-click     = "pavucontrol";
      };

      battery = {
        format          = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-icons    = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        states          = { warning = 30; critical = 15; };
      };

      tray.spacing = 8;
    };

    style = ''
      * { font-family: "JetBrainsMono Nerd Font Mono"; font-size: 13px; border: none; }

      window#waybar {
        background: rgba(30,30,46,0.9);
        color: #cdd6f4;
      }

      #workspaces button {
        padding: 0 8px;
        color: #6c7086;
        border-radius: 6px;
      }
      #workspaces button.active  { color: #cba6f7; background: rgba(203,166,247,0.15); }
      #workspaces button:hover   { color: #89b4fa; }

      #clock, #cpu, #memory, #network, #pulseaudio, #battery, #tray {
        padding: 0 12px;
        margin: 4px 2px;
        border-radius: 6px;
        background: rgba(49,50,68,0.8);
      }

      #clock      { color: #89b4fa; }
      #cpu        { color: #a6e3a1; }
      #memory     { color: #f9e2af; }
      #network    { color: #94e2d5; }
      #pulseaudio { color: #cba6f7; }
      #battery    { color: #a6e3a1; }
      #battery.warning  { color: #fab387; }
      #battery.critical { color: #f38ba8; }
    '';
  };
}

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
      modules-right  = [ "niri/language" "pulseaudio" "network" "cpu" "memory" "battery" "tray" ];

      # Current keyboard layout (switched with Shift+Alt). shortDescription is
      # "en" for the us layout and "ru" for the ru layout → format-en/format-ru.
      "niri/language" = {
        format         = "{short}";
        format-en      = "EN";
        format-ru      = "RU";
        tooltip-format = "{long}";
      };

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

    # ─── yugen-ash (main variant) palette ───────────────────────────────────
    #   bg #151515  surface #303030  fg #D4D4D4  muted #696969
    #   primary #FFBE89  coral #FF9E8B  sage #9db89c  amber #D4A76A
    #   frost #96a8ad  success #7EAB8E  error #F57A7A
    style = ''
      * { font-family: "JetBrainsMono Nerd Font Mono"; font-size: 13px; border: none; }

      window#waybar {
        background: rgba(21,21,21,0.92);
        color: #D4D4D4;
      }

      #workspaces button {
        padding: 0 8px;
        color: #696969;
        border-radius: 6px;
      }
      #workspaces button.active  { color: #FFBE89; background: rgba(255,190,137,0.15); }
      #workspaces button:hover   { color: #FF9E8B; }

      #clock, #cpu, #memory, #network, #pulseaudio, #battery, #language, #tray {
        padding: 0 12px;
        margin: 4px 2px;
        border-radius: 6px;
        background: rgba(48,48,48,0.8);
      }

      #language   { color: #96a8ad; font-weight: bold; }
      #clock      { color: #FFBE89; }
      #cpu        { color: #9db89c; }
      #memory     { color: #D4A76A; }
      #network    { color: #96a8ad; }
      #pulseaudio { color: #FF9E8B; }
      #battery    { color: #7EAB8E; }
      #battery.warning  { color: #D4A76A; }
      #battery.critical { color: #F57A7A; }
    '';
  };
}

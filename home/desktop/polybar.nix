{ pkgs, ... }:
{
  services.polybar = {
    enable = true;
    package = pkgs.polybar;
    script = "polybar main &";
    config = {
      "bar/main" = {
        width = "100%";
        height = 30;
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        font-0 = "JetBrainsMono Nerd Font:size=11;2";
        modules-left = "date";
        modules-right = "pulseaudio network battery";
        tray-position = "right";
        padding = 1;
        module-margin = 1;
      };
      "module/date" = {
        type = "internal/date";
        date = "%a %d %b  %H:%M";
        label-foreground = "#cdd6f4";
      };
      "module/battery" = {
        type = "internal/battery";
        battery = "BAT0";
        adapter = "ADP1";
        format-charging = "<label-charging>";
        format-discharging = "<label-discharging>";
        label-charging = "%percentage%%";
        label-discharging = "%percentage%%";
      };
      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        format-volume = "<label-volume>";
        label-volume = "%percentage%%";
        label-muted = "muted";
      };
      "module/network" = {
        type = "internal/network";
        interface-type = "wireless";
        format-connected = "<label-connected>";
        format-disconnected = "<label-disconnected>";
        label-connected = "%essid%";
        label-disconnected = "off";
      };
    };
  };
}

{ config, ... }:
{
  programs.niri.settings = {
    input.keyboard.xkb.layout = "us";
    input.touchpad = {
      tap = true;
      natural-scroll = true;
    };

    outputs."eDP-1".scale = 1.0;

    layout = {
      gaps = 12;
      center-focused-column = "never";
      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];
      default-column-width.proportion = 1.0 / 2.0;
      focus-ring = {
        enable = true;
        width = 2;
        active.color = "#7aa2f7";
        inactive.color = "#303030";
      };
    };

    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/screenshot-%Y-%m-%d-%H-%M-%S.png";

    spawn-at-startup = [
      { command = [ "waybar" ]; }
      { command = [ "mako" ]; }
      { command = [ "swaybg" "-c" "#1e1e2e" ]; }
    ];

    binds = with config.lib.niri.actions; {
      "Mod+Return".action = spawn "foot";
      "Mod+D".action = spawn "fuzzel";
      "Mod+Q".action = close-window;

      "Mod+Left".action = focus-column-left;
      "Mod+Right".action = focus-column-right;
      "Mod+Down".action = focus-window-down;
      "Mod+Up".action = focus-window-up;
      "Mod+Shift+Left".action = move-column-left;
      "Mod+Shift+Right".action = move-column-right;

      "Mod+1".action = focus-workspace 1;
      "Mod+2".action = focus-workspace 2;
      "Mod+3".action = focus-workspace 3;
      "Mod+4".action = focus-workspace 4;

      "Mod+R".action = switch-preset-column-width;
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;

      "Print".action = screenshot;
      "Mod+Print".action = screenshot-window;

      "XF86AudioRaiseVolume".action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+";
      "XF86AudioLowerVolume".action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-";
      "XF86AudioMute".action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
      "XF86MonBrightnessUp".action = spawn "brightnessctl" "set" "5%+";
      "XF86MonBrightnessDown".action = spawn "brightnessctl" "set" "5%-";

      "Mod+Shift+E".action = quit;
    };
  };
}

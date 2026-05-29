{ config, ... }: {
  home.file."Pictures/wallpaper.jpg".source = ../../../pictures/wallpaper.jpg;

  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb { layout "us" }
            repeat-delay 200
            repeat-rate 30
        }
        touchpad {
            natural-scroll
            tap
            dwt
        }
    }

    layout {
        gaps 8

        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }

        default-column-width { proportion 0.5; }

        focus-ring {
            width 2
            active-color "#cba6f7"
            inactive-color "#313244"
        }

        border { off }
    }

    prefer-no-csd

    screenshot-path "~/Pictures/%Y-%m-%dT%H:%M:%S.png"

    spawn-at-startup "swaybg" "-m" "fill" "-i" "${config.home.homeDirectory}/Pictures/wallpaper.jpg"

    environment {
        QT_QPA_PLATFORM "wayland"
        NIXOS_OZONE_WL  "1"
    }

    binds {
        Mod+Return { spawn "ghostty"; }
        Mod+D      { spawn "rofi" "-show" "drun"; }
        Mod+Q      { close-window; }
        Mod+Shift+Q { quit; }

        // focus
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+J { focus-window-down; }
        Mod+K { focus-window-up; }
        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }

        // move
        Mod+Shift+H { move-column-left; }
        Mod+Shift+L { move-column-right; }
        Mod+Shift+J { move-window-down; }
        Mod+Shift+K { move-window-up; }

        // resize
        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }

        // layout
        Mod+F        { maximize-column; }
        Mod+Shift+F  { fullscreen-window; }
        Mod+C        { center-column; }
        Mod+R        { switch-preset-column-width; }

        // workspaces
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }

        Mod+Shift+1 { move-window-to-workspace 1; }
        Mod+Shift+2 { move-window-to-workspace 2; }
        Mod+Shift+3 { move-window-to-workspace 3; }
        Mod+Shift+4 { move-window-to-workspace 4; }
        Mod+Shift+5 { move-window-to-workspace 5; }
        Mod+Shift+6 { move-window-to-workspace 6; }
        Mod+Shift+7 { move-window-to-workspace 7; }
        Mod+Shift+8 { move-window-to-workspace 8; }
        Mod+Shift+9 { move-window-to-workspace 9; }

        // screenshot
        Print                  { screenshot; }
        Ctrl+Print             { screenshot-window; }
        Alt+Print              { screenshot-screen; }

        // media / brightness
        XF86AudioRaiseVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
        XF86AudioLowerVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
        XF86AudioMute         allow-when-locked=true { spawn "wpctl" "set-mute"   "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86MonBrightnessUp   { spawn "brightnessctl" "set" "5%+"; }
        XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }
    }

    window-rule {
        match app-id="pavucontrol"
        match app-id="blueman-manager"
        open-floating true
    }
  '';
}

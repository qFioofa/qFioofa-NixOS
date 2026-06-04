{ config, ... }:
{
  programs.niri.settings = {
    # -- Environment --
    environment = {
      QT_QPA_PLATFORM = "wayland";
      QT_QPA_PLATFORMTHEME = "gtk3";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    # -- Cursor --
    cursor = {
      theme = "Adwaita";
      size = 24;
      hide-on-key-press = true;
    };

    # -- Input --
    input.keyboard.xkb = {
      layout = "us,ru";
      # ctrl:nocaps -> Caps acts as Ctrl; grp toggle -> Left Alt+Shift switches layout
      options = "ctrl:nocaps,grp:lalt_lshift_toggle";
    };
    input.touchpad = {
      tap = true;
      natural-scroll = true;
    };

    # -- Output --
    outputs."eDP-1".scale = 1.0;

    # -- Hotkey overlay --
    hotkey-overlay.skip-at-startup = true;

    # -- Overview --
    overview.backdrop-color = "#151515";

    # -- Layout --
    layout = {
      gaps = 12;
      center-focused-column = "never";
      always-center-single-column = true;

      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];
      default-column-width.proportion = 1.0 / 2.0;

      focus-ring.enable = false;

      border = {
        enable = true;
        width = 2;
        active.gradient = {
          from = "#FFBE89";
          to = "#FF9E8B";
          angle = 45;
        };
        inactive.color = "#303030";
      };

      shadow = {
        enable = true;
        softness = 30;
        spread = 5;
        offset = { x = 0; y = 5; };
        color = "#00000064";
      };
    };

    # -- Animations --
    animations = {
      workspace-switch.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 1000;
        epsilon = 0.0001;
      };
      window-open.kind.easing = {
        duration-ms = 150;
        curve = "ease-out-expo";
      };
      window-close.kind.easing = {
        duration-ms = 150;
        curve = "ease-out-quad";
      };
      horizontal-view-movement.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };
      window-movement.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };
      window-resize.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };
      config-notification-open-close.kind.spring = {
        damping-ratio = 0.6;
        stiffness = 1000;
        epsilon = 0.001;
      };
    };

    # -- Window rules --
    window-rules = [
      # All windows: slight transparency by default
      {
        opacity = 0.95;
      }
      # Active window: fully opaque
      {
        matches = [{ is-active = true; }];
        opacity = 1.0;
      }
      # Browsers: open wider
      {
        matches = [
          { app-id = "^firefox$"; }
          { app-id = "^chromium-browser$"; }
          { app-id = "^google-chrome$"; }
        ];
        default-column-width = { proportion = 0.75; };
      }
      # Firefox PiP: floating
      {
        matches = [{ app-id = "^firefox$"; title = "^Picture-in-Picture$"; }];
        open-floating = true;
      }
      # Settings/dialog apps: fixed width
      {
        matches = [
          { app-id = "^pavucontrol$"; }
          { app-id = "^nm-connection-editor$"; }
          { app-id = "^blueman-manager$"; }
        ];
        default-column-width = { fixed = 600; };
      }
      # Block sensitive apps from screencasts
      {
        matches = [{ app-id = "^org\\.keepassxc\\.KeePassXC$"; }];
        block-out-from = "screencast";
      }
    ];

    # -- General --
    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/screenshot-%Y-%m-%d-%H-%M-%S.png";
    xwayland-satellite.enable = true;

    # -- Startup --
    spawn-at-startup = [
      { command = [ "waybar" ]; }
      { command = [ "mako" ]; }
      { command = [ "swaybg" "-i" "${../../wallpaper/bg.jpg}" "-m" "fill" ]; }
      { command = [ "wl-paste" "--type" "text" "--watch" "cliphist" "store" ]; }
      { command = [ "wl-paste" "--type" "image" "--watch" "cliphist" "store" ]; }
    ];

    # -- Keybindings --
    binds = with config.lib.niri.actions; {
      # Keyboard layout switching is handled by XKB (Left Alt+Shift, see input.keyboard.xkb)

      # Launch
      "Mod+Return".action = spawn "ghostty";
      "Mod+D".action = spawn "rofi" "-show" "drun";
      "Mod+Q".action = close-window;

      # Clipboard history
      "Mod+V".action = spawn "sh" "-c" "cliphist list | rofi -dmenu -p 'Clipboard' | cliphist decode | wl-copy";

      # Notifications
      "Mod+N".action = spawn "makoctl" "dismiss";
      "Mod+Shift+N".action = spawn "makoctl" "dismiss" "--all";

      # Focus (arrows)
      "Mod+Left".action = focus-column-left;
      "Mod+Right".action = focus-column-right;
      "Mod+Down".action = focus-window-down;
      "Mod+Up".action = focus-window-up;

      # Focus (vim)
      "Mod+H".action = focus-column-left;
      "Mod+L".action = focus-column-right;
      "Mod+J".action = focus-window-down;
      "Mod+K".action = focus-window-up;

      # Move window (arrows)
      "Mod+Shift+Left".action = move-column-left;
      "Mod+Shift+Right".action = move-column-right;
      "Mod+Shift+Down".action = move-window-down;
      "Mod+Shift+Up".action = move-window-up;

      # Move window (vim)
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+L".action = move-column-right;
      "Mod+Shift+J".action = move-window-down;
      "Mod+Shift+K".action = move-window-up;

      # Focus monitor
      "Mod+Ctrl+Left".action = focus-monitor-left;
      "Mod+Ctrl+Right".action = focus-monitor-right;
      "Mod+Ctrl+Down".action = focus-monitor-down;
      "Mod+Ctrl+Up".action = focus-monitor-up;

      # Move column to monitor
      "Mod+Ctrl+Shift+Left".action = move-column-to-monitor-left;
      "Mod+Ctrl+Shift+Right".action = move-column-to-monitor-right;
      "Mod+Ctrl+Shift+Down".action = move-column-to-monitor-down;
      "Mod+Ctrl+Shift+Up".action = move-column-to-monitor-up;

      # Workspaces: focus
      "Mod+1".action = focus-workspace 1;
      "Mod+2".action = focus-workspace 2;
      "Mod+3".action = focus-workspace 3;
      "Mod+4".action = focus-workspace 4;
      "Mod+5".action = focus-workspace 5;
      "Mod+6".action = focus-workspace 6;
      "Mod+7".action = focus-workspace 7;
      "Mod+8".action = focus-workspace 8;
      "Mod+9".action = focus-workspace 9;

      # Workspaces: move window
      "Mod+Shift+1".action.move-window-to-workspace = 1;
      "Mod+Shift+2".action.move-window-to-workspace = 2;
      "Mod+Shift+3".action.move-window-to-workspace = 3;
      "Mod+Shift+4".action.move-window-to-workspace = 4;
      "Mod+Shift+5".action.move-window-to-workspace = 5;
      "Mod+Shift+6".action.move-window-to-workspace = 6;
      "Mod+Shift+7".action.move-window-to-workspace = 7;
      "Mod+Shift+8".action.move-window-to-workspace = 8;
      "Mod+Shift+9".action.move-window-to-workspace = 9;

      # Workspace scroll
      "Mod+Page_Up".action = focus-workspace-up;
      "Mod+Page_Down".action = focus-workspace-down;
      "Mod+Shift+Page_Up".action = move-column-to-workspace-up;
      "Mod+Shift+Page_Down".action = move-column-to-workspace-down;
      "Mod+WheelScrollUp".action = focus-workspace-up;
      "Mod+WheelScrollDown".action = focus-workspace-down;

      # Column layout
      "Mod+R".action = switch-preset-column-width;
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;
      "Mod+C".action = center-column;

      # Column consume/expel
      "Mod+BracketLeft".action = consume-window-into-column;
      "Mod+BracketRight".action = expel-window-from-column;

      # Resize
      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Equal".action = set-column-width "+10%";
      "Mod+Shift+Minus".action = set-window-height "-10%";
      "Mod+Shift+Equal".action = set-window-height "+10%";

      # Screenshots
      "Print".action.screenshot = {};
      "Mod+Print".action.screenshot-window = {};
      "Ctrl+Print".action.screenshot-screen = {};

      # Media keys
      "XF86AudioRaiseVolume".action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+";
      "XF86AudioLowerVolume".action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-";
      "XF86AudioMute".action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
      "XF86AudioMicMute".action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle";
      "XF86MonBrightnessUp".action = spawn "brightnessctl" "set" "5%+";
      "XF86MonBrightnessDown".action = spawn "brightnessctl" "set" "5%-";

      # Session
      "Mod+Shift+E".action = quit;
      "Mod+Shift+P".action = power-off-monitors;
    };
  };
}

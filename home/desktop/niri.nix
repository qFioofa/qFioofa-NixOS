{ config, pkgs, lib, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme) bg bgSurface fgMuted;

  # niri has no bulk "tile into row/column" action, so loop its per-window ops.
  # ponytail: loops the native actions; niri gains a real bulk op → drop this.
  niriArrange = pkgs.writeShellScriptBin "niri-arrange" ''
    export PATH="${lib.makeBinPath [ pkgs.niri pkgs.jq ]}:$PATH"
    set -euo pipefail
    wins=$(niri msg -j windows)
    f=$(jq -c '[.[] | select(.is_focused)][0]' <<<"$wins")
    ws=$(jq '.workspace_id' <<<"$f")
    case "''${1:-}" in
      row)
        # Expel every window in the focused column so they sit side by side.
        col=$(jq '.layout.pos_in_scrolling_layout[0]' <<<"$f")
        n=$(jq --argjson ws "$ws" --argjson col "$col" \
          '[.[] | select(.workspace_id==$ws and .is_floating==false
            and (.layout.pos_in_scrolling_layout // [0])[0]==$col)] | length' <<<"$wins")
        for ((i = 1; i < n; i++)); do
          niri msg action expel-window-from-column
          niri msg action focus-column-left
        done
        ;;
      column)
        # Gather every tiled window on the workspace into one vertical stack.
        n=$(jq --argjson ws "$ws" \
          '[.[] | select(.workspace_id==$ws and .is_floating==false)] | length' <<<"$wins")
        niri msg action move-column-to-first
        for ((i = 1; i < n; i++)); do niri msg action consume-window-into-column; done
        ;;
      *) echo "usage: niri-arrange {row|column}" >&2; exit 1 ;;
    esac
  '';
in
{
  programs.niri.settings = {
    environment = {
      QT_QPA_PLATFORM = "wayland";
      QT_QPA_PLATFORMTHEME = "gtk3";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    cursor = {
      theme = "Adwaita";
      size = 24;
      hide-on-key-press = true;
    };

    input.keyboard.xkb = {
      layout = "us,ru";
      options = "ctrl:nocaps,grp:lalt_lshift_toggle";
    };
    input.touchpad = {
      # tap-to-click: 1-finger = left, 2-finger = right, 3-finger = middle.
      tap = true;
      tap-button-map = "left-right-middle";
      natural-scroll = true;
      dwt = true;                       # disable while typing
      accel-profile = "adaptive";
      scroll-method = "two-finger";
      click-method = "button-areas";
      disabled-on-external-mouse = false;
    };
    input.mouse.natural-scroll = false;

    gestures.hot-corners.enable = true;

    outputs."eDP-1".scale = 1.0;

    hotkey-overlay.skip-at-startup = true;

    overview.backdrop-color = bg;

    layout = {
      gaps = 12;
      center-focused-column = "always";
      always-center-single-column = true;

      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];
      default-column-width.proportion = 1.0 / 2.0;

      focus-ring = {
        enable = true;
        width = 1;
        active.color = fgMuted;
        inactive.color = bgSurface;
      };

      border.enable = false;

      shadow = {
        enable = true;
        softness = 30;
        spread = 5;
        offset = { x = 0; y = 5; };
        color = "#00000064";
      };
    };

    animations = {
      slowdown = 1.0;

      workspace-switch.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 750;
        epsilon = 0.0001;
      };

      window-open.kind.spring = {
        damping-ratio = 0.82;
        stiffness = 700;
        epsilon = 0.0001;
      };
      window-close.kind.easing = {
        duration-ms = 130;
        curve = "ease-out-quad";
      };

      horizontal-view-movement.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 750;
        epsilon = 0.0001;
      };
      window-movement.kind.spring = {
        damping-ratio = 0.88;
        stiffness = 750;
        epsilon = 0.0001;
      };
      window-resize.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 850;
        epsilon = 0.0001;
      };

      overview-open-close.kind.spring = {
        damping-ratio = 0.9;
        stiffness = 800;
        epsilon = 0.0001;
      };

      screenshot-ui-open.kind.easing = {
        duration-ms = 200;
        curve = "ease-out-quad";
      };

      config-notification-open-close.kind.spring = {
        damping-ratio = 0.6;
        stiffness = 1000;
        epsilon = 0.001;
      };
    };

    window-rules = [
      {
        # Small rounded corners for every window. clip-to-geometry rounds the
        # window surface itself (and cuts client-side shadows), so the focus
        # ring and shadow follow the same radius.
        geometry-corner-radius = {
          top-left = 8.0;
          top-right = 8.0;
          bottom-right = 8.0;
          bottom-left = 8.0;
        };
        clip-to-geometry = true;
      }
      {
        matches = [
          { app-id = "^firefox$"; }
          { app-id = "^chromium-browser$"; }
          { app-id = "^google-chrome$"; }
        ];
        default-column-width = { proportion = 0.75; };
      }
      {
        matches = [{ app-id = "^firefox$"; title = "^Picture-in-Picture$"; }];
        open-floating = true;
      }
      {
        matches = [
          { app-id = "^pavucontrol$"; }
          { app-id = "^nm-connection-editor$"; }
          { app-id = "^blueman-manager$"; }
        ];
        default-column-width = { fixed = 600; };
      }
      {
        matches = [{ app-id = "^org\\.keepassxc\\.KeePassXC$"; }];
        block-out-from = "screencast";
      }
      {
        # First window opened right after login (empty desktop) starts
        # fullscreen. at-startup matches windows created within the first ~60s
        # of the niri session; the layer-shell startup pieces (waybar,
        # wallpaper, polkit agent, cliphist) are not windows, so this only
        # affects the first real app you launch.
        matches = [{ at-startup = true; }];
        # The terminal (Mod+Return) is the usual first thing launched right
        # after login, but it should open at normal column width, not fullscreen.
        excludes = [{ app-id = "^com\\.mitchellh\\.ghostty$"; }];
        open-fullscreen = true;
      }
    ];

    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/screenshot-%Y-%m-%d-%H-%M-%S.png";
    xwayland-satellite = {
      enable = true;
      path = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
    };

    spawn-at-startup = [
      { command = [ "waybar" ]; }
      { command = [ "${pkgs.swaybg}/bin/swaybg" "-i" "${theme.wallpaper}" "-m" "fill" ]; }
      # Polkit authentication agent for GUI auth prompts (the other user
      # services already run via systemd).
      { command = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]; }
      { command = [ "wl-paste" "--type" "text" "--watch" "cliphist" "store" ]; }
      { command = [ "wl-paste" "--type" "image" "--watch" "cliphist" "store" ]; }
    ];

    binds = with config.lib.niri.actions; {

      "Mod+Return".action = spawn "ghostty";
      # finalPackage is the rofi wrapped with its plugins (calc/emoji); niri's
      # spawn PATH is not guaranteed to resolve them, so reference it directly.
      "Mod+D".action = spawn "${config.programs.rofi.finalPackage}/bin/rofi" "-show" "drun";
      "Mod+Period".action = spawn "${config.programs.rofi.finalPackage}/bin/rofi" "-show" "emoji";
      "Alt+Tab".action = spawn "window-switcher";
      "Mod+E".action = spawn "nemo";
      "Mod+Q".action = close-window;

      "Mod+Shift+Q".action = spawn "powermenu";
      # wlogout-toggle and lock are home-manager packages; niri's spawn PATH
      # does not reliably include the HM profile, so reference it by absolute
      # path to make the binds fire regardless of PATH.
      "Mod+Escape".action = spawn "${config.home.profileDirectory}/bin/wlogout-toggle";
      "Mod+Alt+L".action = spawn "${config.home.profileDirectory}/bin/lock";

      "Mod+V".action = spawn "${config.home.profileDirectory}/bin/clipboard-menu";

      "Mod+N".action = spawn "swaync-client" "-cl";
      "Mod+Shift+N".action = spawn "swaync-client" "-C";

      "Mod+Shift+W".action = spawn "wifi-popup";
      "Mod+Shift+B".action = spawn "bt-popup";

      "Mod+Shift+C".action = spawn "calendar";

      # SIGUSR1 toggles waybar visibility.
      "Mod+B".action = spawn "${pkgs.procps}/bin/pkill" "--signal" "SIGUSR1" "waybar";
      "Mod+O".action = toggle-overview;
      "Mod+Slash".action = spawn "help-manual";

      "Mod+Left".action = focus-column-left;
      "Mod+Right".action = focus-column-right;
      "Mod+Down".action = focus-window-down;
      "Mod+Up".action = focus-window-up;

      "Mod+H".action = focus-column-left;
      "Mod+L".action = focus-column-right;
      "Mod+J".action = focus-window-down;
      "Mod+K".action = focus-window-up;

      "Mod+Shift+Left".action = move-column-left;
      "Mod+Shift+Right".action = move-column-right;
      "Mod+Shift+Down".action = move-window-down;
      "Mod+Shift+Up".action = move-window-up;

      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+L".action = move-column-right;
      "Mod+Shift+J".action = move-window-down;
      "Mod+Shift+K".action = move-window-up;

      "Mod+Ctrl+Left".action = focus-monitor-left;
      "Mod+Ctrl+Right".action = focus-monitor-right;
      "Mod+Ctrl+Down".action = focus-monitor-down;
      "Mod+Ctrl+Up".action = focus-monitor-up;

      "Mod+Ctrl+Shift+Left".action = move-column-to-monitor-left;
      "Mod+Ctrl+Shift+Right".action = move-column-to-monitor-right;
      "Mod+Ctrl+Shift+Down".action = move-column-to-monitor-down;
      "Mod+Ctrl+Shift+Up".action = move-column-to-monitor-up;

      "Mod+1".action = focus-workspace 1;
      "Mod+2".action = focus-workspace 2;
      "Mod+3".action = focus-workspace 3;
      "Mod+4".action = focus-workspace 4;
      "Mod+5".action = focus-workspace 5;
      "Mod+6".action = focus-workspace 6;
      "Mod+7".action = focus-workspace 7;
      "Mod+8".action = focus-workspace 8;
      "Mod+9".action = focus-workspace 9;

      "Mod+Shift+1".action.move-window-to-workspace = 1;
      "Mod+Shift+2".action.move-window-to-workspace = 2;
      "Mod+Shift+3".action.move-window-to-workspace = 3;
      "Mod+Shift+4".action.move-window-to-workspace = 4;
      "Mod+Shift+5".action.move-window-to-workspace = 5;
      "Mod+Shift+6".action.move-window-to-workspace = 6;
      "Mod+Shift+7".action.move-window-to-workspace = 7;
      "Mod+Shift+8".action.move-window-to-workspace = 8;
      "Mod+Shift+9".action.move-window-to-workspace = 9;

      "Mod+Page_Up".action = focus-workspace-up;
      "Mod+Page_Down".action = focus-workspace-down;
      "Mod+Shift+Page_Up".action = move-column-to-workspace-up;
      "Mod+Shift+Page_Down".action = move-column-to-workspace-down;
      "Mod+WheelScrollUp".action = focus-workspace-up;
      "Mod+WheelScrollDown".action = focus-workspace-down;

      # Column/workspace stepping uses niri's built-in three-finger swipe. Do
      # NOT bind two-finger (TouchpadScroll*): two-finger is the scroll gesture,
      # so binding it consumes scroll events and breaks scrolling in apps.

      "Mod+R".action = switch-preset-column-width;
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;
      "Mod+C".action = center-column;

      "Mod+BracketLeft".action = consume-window-into-column;
      "Mod+BracketRight".action = expel-window-from-column;

      # Move a window sideways between adjacent columns (build a row by hand).
      "Mod+Shift+BracketLeft".action = consume-or-expel-window-left;
      "Mod+Shift+BracketRight".action = consume-or-expel-window-right;

      # Bulk: stack all workspace windows into one column / spread the focused
      # column back out into a row. Handles any number of windows at once.
      "Mod+Backslash".action = spawn "niri-arrange" "column";
      "Mod+Shift+Backslash".action = spawn "niri-arrange" "row";

      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Equal".action = set-column-width "+10%";
      "Mod+Shift+Minus".action = set-window-height "-10%";
      "Mod+Shift+Equal".action = set-window-height "+10%";

      # Print: select region → straight to clipboard + saved file (fast path).
      # Shift+Print: select region → satty for Lightshot-style annotation.
      # Ctrl+Print: whole screen. Mod+Print: the focused window (niri built-in).
      "Print".action = spawn "${config.home.profileDirectory}/bin/screenshot";
      "Shift+Print".action = spawn "${config.home.profileDirectory}/bin/screenshot" "edit";
      "Ctrl+Print".action = spawn "${config.home.profileDirectory}/bin/screenshot" "full";
      "Mod+Print".action.screenshot-window = {};

      "XF86AudioRaiseVolume".action = spawn "swayosd-client" "--output-volume" "raise";
      "XF86AudioLowerVolume".action = spawn "swayosd-client" "--output-volume" "lower";
      "XF86AudioMute".action = spawn "swayosd-client" "--output-volume" "mute-toggle";
      "XF86AudioMicMute".action = spawn "swayosd-client" "--input-volume" "mute-toggle";
      "XF86MonBrightnessUp".action = spawn "swayosd-client" "--brightness" "raise";
      "XF86MonBrightnessDown".action = spawn "swayosd-client" "--brightness" "lower";

      "Mod+Shift+E".action = quit;
      "Mod+Shift+P".action = power-off-monitors;
    };
  };

  home.packages = [ niriArrange ];

  # screenshot-path won't create missing parents, so ensure the dir exists.
  home.file."Pictures/Screenshots/.keep".text = "";
}

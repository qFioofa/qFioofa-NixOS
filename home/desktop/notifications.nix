{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme)
    bg bgSurface fg fgDim fgMuted primary error font radius radiusInner;

  # Sound played for critical notifications (point 3, scripts/rules engine).
  criticalSound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/dialog-warning.oga";
  playSound = "${pkgs.pipewire}/bin/pw-play ${criticalSound}";
in
{
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "bottom";
      control-center-width = 380;
      control-center-margin-top = 8;
      control-center-margin-bottom = 8;
      control-center-margin-right = 8;
      notification-window-width = 360;
      timeout = 10;
      timeout-low = 6;
      timeout-critical = 0;
      fit-to-screen = false;

      # --- Point 2: richer per-notification information ---
      relative-timestamps = true; # "2m ago" in the history list
      image-visibility = "when-available"; # show app/album images when present
      notification-icon-size = 48; # app-identity icon
      notification-body-image-height = 160; # screenshot / album-art thumbnails
      notification-body-image-width = 320;

      # --- Point 3: behaviour / functionality ---
      keyboard-shortcuts = true; # arrow-key navigation in the control center
      notification-grouping = true; # group per app — renders the app-icon + name header
      hide-on-clear = true;
      hide-on-action = true; # close the popup once its (default) action fires
      script-fail-notify = true;

      # Left-clicking a notification triggers the app's *default action*, which
      # for most apps (Discord, browsers, Telegram, mail) opens/raises the app
      # that sent it. swaync does this out of the box — hide-on-action just makes
      # the popup get out of the way afterwards.

      widgets = [ "title" "buttons-grid" "dnd" "notifications" ];
      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear all";
        };
        dnd.text = "Do not disturb";

        # --- Point 5: unify toggles — quick actions reuse the existing scripts. ---
        buttons-grid.actions = [
          { label = "󰖩"; command = "wifi-popup"; }
          { label = "󰂯"; command = "bt-popup"; }
          { label = "󰄀"; command = "niri msg action screenshot"; }
          { label = "󰍁"; command = "lock"; }
          { label = "󰐥"; command = "powermenu"; }
        ];
      };

      # --- Point 3: rules engine. Play a sound on every critical notification.
      # Add more rules by matching app-name/summary/body/urgency/category. ---
      scripts.critical-sound = {
        urgency = "Critical";
        run-on = "receive";
        exec = playSound;
      };
    };
    style = builtins.readFile (pkgs.replaceVars ./themes/notifications.css {
      inherit bg bgSurface fg fgDim fgMuted primary error font radius radiusInner;
    });
  };
}

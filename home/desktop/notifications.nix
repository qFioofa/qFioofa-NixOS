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
      timeout = 5;
      timeout-low = 3;
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
    style = ''
      * {
        font-family: "${font}";
        font-size: 13px;
      }

      .control-center {
        background: rgba(21, 21, 21, 0.96);
        border: 1px solid ${bgSurface};
        border-radius: ${radius};
        color: ${fg};
      }

      /* Notification card. A left accent bar encodes urgency at a glance
         (point 2): muted = low, accent = normal, error = critical. */
      .control-center .notification-row .notification-background .notification,
      .floating-notifications .notification-row .notification-background .notification {
        background: rgba(21, 21, 21, 0.96);
        border: 1px solid ${bgSurface};
        border-left: 3px solid ${primary};
        border-radius: 10px;
        margin: 6px;
        padding: 4px;
      }

      .notification-row .notification-background .notification.low {
        border-left-color: ${fgMuted};
      }

      .notification-row .notification-background .notification.critical {
        border-left-color: ${error};
        border-color: ${error};
      }

      .notification-content {
        color: ${fg};
        padding: 6px;
      }

      /* Small gap between the app profile (icon) and the message content. */
      .notification-content .text-box {
        margin-left: 8px;
      }

      .summary {
        color: ${fg};
        font-weight: bold;
      }

      /* Relative timestamp (point 2). */
      .time {
        color: ${fgMuted};
        font-size: 11px;
      }

      .body {
        color: ${fgDim};
      }

      /* App icon + inline images, rounded to match the cards (point 2). */
      .notification-content .image,
      .notification-content .app-icon {
        border-radius: 6px;
      }

      .body-image {
        border-radius: ${radiusInner};
        margin-top: 6px;
      }

      /* Click-to-open affordance: the whole card is the default action. */
      .notification-default-action {
        border-radius: 10px;
      }

      .notification-default-action:hover {
        background: ${bgSurface};
      }

      /* Action buttons (point 3) — e.g. Discord "Reply"/"Mark read". */
      .notification-action {
        background: ${bgSurface};
        color: ${fg};
        border: 1px solid ${bgSurface};
        border-radius: ${radiusInner};
        margin: 4px;
        padding: 4px 10px;
      }

      .notification-action:hover {
        background: ${primary};
        color: ${bg};
      }

      /* Inline replies (point 3). */
      .inline-reply {
        margin-top: 6px;
      }

      .inline-reply-entry {
        background: ${bg};
        color: ${fg};
        border: 1px solid ${bgSurface};
        border-radius: ${radiusInner};
        padding: 4px 8px;
      }

      .inline-reply-button {
        background: ${bgSurface};
        color: ${fg};
        border: 1px solid ${bgSurface};
        border-radius: ${radiusInner};
        margin-left: 6px;
        padding: 4px 10px;
      }

      .inline-reply-button:hover {
        background: ${primary};
        color: ${bg};
      }

      /* App "profile" header on top of each app's notifications:
         the system app icon + the app name, with a small gap before the
         message content below. */
      .notification-group-headers {
        padding: 2px 6px;
        margin-bottom: 6px;
      }

      .notification-group-icon {
        color: ${fg};
        -gtk-icon-size: 22px;
        margin-right: 8px;
      }

      .notification-group-header {
        /* The app-name label. */
        color: ${primary};
        font-weight: bold;
      }

      .notification-group-collapse-button,
      .notification-group-close-all-button {
        background: ${bgSurface};
        color: ${fg};
        border-radius: ${radiusInner};
        padding: 2px 8px;
      }

      .notification-group-collapse-button:hover,
      .notification-group-close-all-button:hover {
        background: ${primary};
        color: ${bg};
      }

      /* Progress notifications (downloads, volume from progress-capable apps). */
      .notification progressbar,
      .notification trough {
        background: ${bgSurface};
        border-radius: 999px;
      }

      .notification progress {
        background: ${primary};
        border-radius: 999px;
      }

      .close-button {
        background: transparent;
        color: ${fgMuted};
        border-radius: ${radiusInner};
      }

      .close-button:hover {
        background: ${bgSurface};
        color: ${fg};
      }

      .control-center .widget-title {
        color: ${fg};
        margin: 8px;
      }

      .control-center .widget-title button {
        background: ${bgSurface};
        color: ${fg};
        border-radius: ${radiusInner};
        padding: 4px 10px;
      }

      .control-center .widget-title button:hover {
        background: ${primary};
        color: ${bg};
      }

      .widget-dnd {
        color: ${fg};
        margin: 8px;
      }

      .widget-dnd > switch {
        background: ${bgSurface};
        border-radius: 999px;
      }

      .widget-dnd > switch:checked {
        background: ${primary};
      }

      /* Quick-toggle grid (point 5). */
      .widget-buttons-grid {
        padding: 8px;
        margin: 8px;
        background: transparent;
      }

      .widget-buttons-grid button,
      .widget-buttons-grid > flowbox > flowboxchild > button {
        background: ${bgSurface};
        color: ${fg};
        border-radius: ${radiusInner};
        padding: 8px;
        margin: 4px;
        font-size: 16px;
      }

      .widget-buttons-grid button:hover,
      .widget-buttons-grid > flowbox > flowboxchild > button:hover {
        background: ${primary};
        color: ${bg};
      }

      .widget-buttons-grid button.toggle:checked {
        background: ${primary};
        color: ${bg};
      }
    '';
  };
}

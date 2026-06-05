{ ... }:
let
  theme = import ../../theme.nix;
in
{
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      control-center-width = 380;
      control-center-margin-top = 8;
      control-center-margin-bottom = 8;
      control-center-margin-right = 8;
      notification-window-width = 360;
      timeout = 5;
      timeout-low = 3;
      timeout-critical = 0;
      fit-to-screen = false;
      widgets = [ "title" "dnd" "notifications" ];
      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear all";
        };
        dnd.text = "Do not disturb";
      };
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
      }

      .control-center {
        background: rgba(21, 21, 21, 0.96);
        border: 1px solid ${theme.bgSurface};
        border-radius: 12px;
        color: ${theme.fg};
      }

      .control-center .notification-row .notification-background .notification,
      .floating-notifications .notification-row .notification-background .notification {
        background: ${theme.bg};
        border: 1px solid ${theme.bgSurface};
        border-radius: 10px;
        margin: 6px;
        padding: 4px;
      }

      .notification-row .notification-background .notification.critical {
        border-color: ${theme.error};
      }

      .notification-content {
        color: ${theme.fg};
        padding: 6px;
      }

      .summary {
        color: ${theme.fg};
        font-weight: bold;
      }

      .body {
        color: ${theme.fgDim};
      }

      .close-button {
        background: transparent;
        color: ${theme.fgMuted};
        border-radius: 8px;
      }

      .close-button:hover {
        background: ${theme.bgSurface};
        color: ${theme.fg};
      }

      .control-center .widget-title {
        color: ${theme.fg};
        margin: 8px;
      }

      .control-center .widget-title button {
        background: ${theme.bgSurface};
        color: ${theme.fg};
        border-radius: 8px;
        padding: 4px 10px;
      }

      .control-center .widget-title button:hover {
        background: ${theme.primary};
        color: ${theme.bg};
      }

      .widget-dnd {
        color: ${theme.fg};
        margin: 8px;
      }

      .widget-dnd > switch {
        background: ${theme.bgSurface};
        border-radius: 999px;
      }

      .widget-dnd > switch:checked {
        background: ${theme.primary};
      }
    '';
  };
}

{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme)
    bg bgSurface fg fgDim fgMuted
    primary warning error
    violet tide amber;

  # A compact, centered rofi power menu — a small popup instead of the
  # fullscreen wlogout overlay. Each row is "<icon>  <label>".
  menuTheme = pkgs.writeText "powermenu.rasi" ''
    * {
      bg:         ${bg};
      bg-surface: ${bgSurface};
      fg:         ${fg};
      fg-dim:     ${fgDim};
      fg-muted:   ${fgMuted};
      accent:     ${primary};
      danger:     ${error};
      background-color: transparent;
      text-color:       @fg;
    }
    window {
      width:         260px;
      border:        2px;
      border-color:  @accent;
      border-radius: 12px;
      background-color: @bg;
      location: center;
    }
    mainbox {
      padding: 12px;
      spacing: 8px;
      background-color: transparent;
    }
    inputbar {
      enabled: false;
    }
    listview {
      lines:    5;
      spacing:  4px;
      scrollbar: false;
      background-color: transparent;
    }
    element {
      padding:       10px 14px;
      spacing:       12px;
      border-radius: 8px;
      background-color: transparent;
      text-color: @fg-dim;
    }
    element selected {
      background-color: @bg-surface;
      text-color: @accent;
    }
    element-text {
      text-color: inherit;
      vertical-align: 0.5;
    }
  '';

  powermenu = pkgs.writeShellScriptBin "powermenu" ''
    # item COLOR ICON LABEL — accent-coloured icon per action so the menu isn't
    # one flat colour (Shutdown/Reboot lean on the warning/danger hues).
    item() { printf '<span color="%s" weight="bold">%s</span>   %s\n' "$1" "$2" "$3"; }

    chosen=$( { \
      item "${tide}"    "󰍁" "Lock"; \
      item "${amber}"   "󰍃" "Logout"; \
      item "${violet}"  "󰒲" "Suspend"; \
      item "${warning}" "󰜉" "Reboot"; \
      item "${error}"   "󰐥" "Shutdown"; \
      } | ${pkgs.rofi}/bin/rofi -dmenu -i -markup-rows -p "Power" \
          -theme ${menuTheme} \
          -no-custom -format s)

    case "$chosen" in
      *Lock*)     lock ;;
      *Logout*)   niri msg action quit --skip-confirmation ;;
      *Suspend*)  systemctl suspend ;;
      *Reboot*)   systemctl reboot ;;
      *Shutdown*) systemctl poweroff ;;
    esac
  '';
in
{
  home.packages = [ powermenu ];
}

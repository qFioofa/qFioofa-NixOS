{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme) bg bgSurface fg fgDim fgMuted primary;

  # A centered, two-column keybinding cheat-sheet. Visually nicer than niri's
  # built-in hotkey overlay: themed, rounded, with accent section headers and
  # dimmed descriptions. Bound to Mod+Slash.
  helpTheme = pkgs.writeText "help.rasi" ''
    * {
      bg:         ${bg};
      bg-surface: ${bgSurface};
      fg:         ${fg};
      fg-dim:     ${fgDim};
      fg-muted:   ${fgMuted};
      accent:     ${primary};
      background-color: transparent;
      text-color:       @fg;
      font: "JetBrainsMono Nerd Font 11";
    }
    window {
      width:         620px;
      border:        2px;
      border-color:  @accent;
      border-radius: 12px;
      background-color: @bg;
      location: center;
    }
    mainbox {
      padding: 16px;
      spacing: 10px;
      background-color: transparent;
    }
    inputbar {
      padding: 6px 12px;
      border-radius: 8px;
      background-color: @bg-surface;
      children: [ prompt ];
    }
    prompt {
      text-color: @accent;
      font: "JetBrainsMono Nerd Font Bold 12";
    }
    listview {
      lines:    24;
      spacing:  2px;
      scrollbar: false;
      background-color: transparent;
    }
    element {
      padding:       4px 12px;
      border-radius: 6px;
      background-color: transparent;
    }
    element selected {
      background-color: @bg-surface;
    }
    element-text {
      text-color: inherit;
      vertical-align: 0.5;
      highlight: none;
    }
  '';

  helpManual = pkgs.writeShellScriptBin "help-manual" ''
    # head <title> — accent section header
    head() { printf '<span color="${primary}" weight="bold" size="large">%s</span>\n' "$1"; }
    # row <keys> <description> — accent key column + dimmed description
    row() {
      printf '<span color="${fg}" weight="bold">%-26s</span><span color="${fgDim}">%s</span>\n' "$1" "$2"
    }

    {
      head "󰣆  Applications"
      row "Mod + Return"            "Terminal (ghostty)"
      row "Mod + D"                 "App launcher (rofi)"
      row "Mod + E"                 "File manager (nemo)"
      row "Mod + V"                 "Clipboard history"
      row "Mod + Shift+W"           "Wi-Fi menu"
      row "Mod + Shift+B"           "Bluetooth menu"

      head "  Windows"
      row "Mod + Q"                 "Close window"
      row "Mod + H / J / K / L"     "Focus left / down / up / right"
      row "Mod + Shift + H J K L"   "Move window in direction"
      row "Mod + R"                 "Cycle preset column widths"
      row "Mod + F"                 "Maximize column"
      row "Mod + Shift + F"         "Fullscreen window"
      row "Mod + C"                 "Center column"
      row "Mod + [ / ]"             "Consume / expel window from column"
      row "Mod + - / ="             "Shrink / grow column width"

      head "  Workspaces & Monitors"
      row "Mod + 1..9"              "Focus workspace"
      row "Mod + Shift + 1..9"      "Move window to workspace"
      row "Mod + Page Up/Down"      "Focus workspace up / down"
      row "Mod + Ctrl + Arrows"     "Focus monitor in direction"
      row "Mod + O"                 "Toggle overview"

      head "  Desktop"
      row "Mod + B"                 "Toggle waybar"
      row "Mod + N / Shift+N"       "Notifications close / center"
      row "Mod + Alt + L"           "Lock screen"
      row "Mod + Shift + Q"         "Power menu"
      row "Print"                   "Screenshot (region)"
      row "Mod + Print"             "Screenshot (window)"
      row "Ctrl + Print"            "Screenshot (screen)"
      row "Mod + Slash"             "This help"
    } | ${pkgs.rofi}/bin/rofi -dmenu -i -markup-rows \
          -p "Keybindings" \
          -theme ${helpTheme} \
          -no-custom
  '';
in
{
  home.packages = [ helpManual ];
}

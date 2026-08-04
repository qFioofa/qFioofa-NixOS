#!/usr/bin/env bash
# The key column is tinted with the current section's accent so each block
# reads as a group; SEC carries that colour from head() to its rows.
SEC="@primary@"
# head <icon+title> <color> — coloured section header; also sets SEC.
head() {
  SEC="$2"
  printf '<span color="%s" weight="bold" size="large">%s</span>\n' "$2" "$1"
}
# row <keys> <description> — section-accent key column + dimmed description.
row() {
  printf '<span color="%s" weight="bold">%-26s</span><span color="@fgDim@">%s</span>\n' "$SEC" "$1" "$2"
}

{
  head "󰣆   Applications" "@primary@"
  row "Mod + Return"            "Terminal (ghostty)"
  row "Mod + D"                 "App launcher (rofi)"
  row "Mod + E"                 "File manager (nemo)"
  row "Mod + V"                 "Clipboard history"
  row "Mod + Shift+W"           "Wi-Fi menu"
  row "Mod + Shift+B"           "Bluetooth menu"
  row "Mod + Shift+C"           "Calendar & date tools"

  head "󰖯   Windows" "@tide@"
  row "Mod + Q"                 "Close window"
  row "Mod + H / J / K / L"     "Focus left / down / up / right"
  row "Mod + Shift + H J K L"   "Move window in direction"
  row "Mod + R"                 "Cycle preset column widths"
  row "Mod + F"                 "Maximize column"
  row "Mod + Shift + F"         "Fullscreen window"
  row "Mod + C"                 "Center column"
  row "Mod + [ / ]"             "Consume / expel window from column"
  row "Mod + Shift + [ / ]"     "Move window left / right between columns"
  row "Mod + G"                "2/3 focused + 1/3 neighbour (task on the side)"
  row "Mod + \\"                "Stack all windows vertically, equal height (fit top-to-bottom)"
  row "Mod + Shift + \\"        "Spread column into an equal-width row (fit side by side)"
  row "Mod + - / ="             "Shrink / grow column width"

  head "󰍹   Workspaces & Monitors" "@violet@"
  row "Mod + 1..9"              "Focus workspace"
  row "Mod + Shift + 1..9"      "Move window to workspace"
  row "Mod + Page Up/Down"      "Focus workspace up / down"
  row "Mod + Ctrl + Arrows"     "Focus monitor in direction"
  row "Mod + O"                 "Toggle overview"

  head "󰇄   Desktop" "@amber@"
  row "Mod + B"                 "Toggle waybar"
  row "Mod + N / Shift+N"       "Notifications close / center"
  row "Mod + Alt + L"           "Lock screen"
  row "Mod + Shift + Q"         "Power menu (rofi)"
  row "Mod + Escape"            "Power menu (wlogout)"
  row "Print"                   "Screenshot (region)"
  row "Mod + Print"             "Screenshot (window)"
  row "Ctrl + Print"            "Screenshot (screen)"
  row "Mod + Slash"             "This help"
} | @rofi@ -dmenu -i -markup-rows \
      -p "Keybindings" \
      -theme @helpTheme@ \
      -no-custom

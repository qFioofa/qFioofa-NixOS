{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme) bg bgSurface fg fgDim fgMuted primary radius radiusInner border;

  rofi = "${pkgs.rofi}/bin/rofi";
  jq = "${pkgs.jq}/bin/jq";
  sed = "${pkgs.gnused}/bin/sed";

  # A centered rofi with the search bar enabled — type to filter open windows
  # by app id or title, just like the drun launcher but scoped to live windows.
  switcherTheme = pkgs.writeText "switcher.rasi" ''
    * {
      bg:         ${bg};
      bg-surface: ${bgSurface};
      fg:         ${fg};
      fg-dim:     ${fgDim};
      fg-muted:   ${fgMuted};
      accent:     ${primary};
      background-color: transparent;
      text-color:       @fg;
    }
    window {
      width:         640px;
      border:        ${border};
      border-color:  @accent;
      border-radius: ${radius};
      background-color: @bg;
      location: center;
    }
    mainbox {
      padding: 12px;
      spacing: 8px;
      background-color: transparent;
    }
    inputbar {
      spacing: 8px;
      padding: 8px 12px;
      border-radius: ${radiusInner};
      background-color: @bg-surface;
      children: [ prompt, entry ];
    }
    prompt { text-color: @accent; }
    entry {
      placeholder: "Search windows...";
      placeholder-color: @fg-muted;
      text-color: @fg;
    }
    listview {
      lines:    10;
      spacing:  4px;
      scrollbar: false;
      background-color: transparent;
    }
    element {
      padding: 8px 12px;
      spacing: 8px;
      border-radius: ${radiusInner};
      background-color: transparent;
      text-color: @fg-dim;
    }
    element selected {
      background-color: @bg-surface;
      text-color: @accent;
    }
    element-text { text-color: inherit; vertical-align: 0.5; }
  '';

  # Rofi window switcher for niri. Lists every open window ("app · title"),
  # filterable by typing, and raises/focuses the chosen one. The window id is
  # kept in a parallel list and recovered from rofi's selected index (-format i)
  # so it never has to be shown to the user.
  windowSwitcher = pkgs.writeShellScriptBin "window-switcher" ''
    data=$(niri msg --json windows 2>/dev/null)
    [ -z "$data" ] && exit 0

    ids=$(printf '%s' "$data" | ${jq} -r '.[].id')
    [ -z "$ids" ] && exit 0

    chosen=$(printf '%s' "$data" \
      | ${jq} -r '.[] | "\(.app_id // "?")  ·  \(.title // "")"' \
      | ${rofi} -dmenu -i -p "Windows" -theme ${switcherTheme} \
          -no-custom -format i)
    [ -z "$chosen" ] && exit 0

    id=$(printf '%s' "$ids" | ${sed} -n "$((chosen + 1))p")
    [ -z "$id" ] && exit 0

    niri msg action focus-window --id "$id"
  '';
in
{
  home.packages = [ windowSwitcher ];
}

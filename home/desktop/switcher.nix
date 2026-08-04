{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme) bg bgSurface fg fgDim fgMuted primary radius radiusInner border;

  # A centered rofi with the search bar enabled — type to filter open windows
  # by app id or title, just like the drun launcher but scoped to live windows.
  switcherTheme = pkgs.replaceVars ./themes/switcher.rasi {
    inherit bg bgSurface fg fgDim fgMuted primary radius radiusInner border;
  };

  # Rofi window switcher for niri. Lists every open window ("app · title"),
  # filterable by typing, and raises/focuses the chosen one. The window id is
  # kept in a parallel list and recovered from rofi's selected index (-format i)
  # so it never has to be shown to the user.
  windowSwitcher = pkgs.writeShellScriptBin "window-switcher" (builtins.readFile (pkgs.replaceVars ./scripts/window-switcher.sh {
    rofi = "${pkgs.rofi}/bin/rofi";
    jq = "${pkgs.jq}/bin/jq";
    sed = "${pkgs.gnused}/bin/sed";
    switcherTheme = "${switcherTheme}";
  }));
in
{
  home.packages = [ windowSwitcher ];
}

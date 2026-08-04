{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme)
    bg bgSurface fg fgDim fgMuted
    primary violet tide amber;

  helpTheme = pkgs.replaceVars ./themes/help.rasi {
    inherit bg bgSurface fg fgDim fgMuted primary;
  };

  helpManual = pkgs.writeShellScriptBin "help-manual" (builtins.readFile (pkgs.replaceVars ./scripts/help-manual.sh {
    rofi = "${pkgs.rofi}/bin/rofi";
    helpTheme = "${helpTheme}";
    inherit primary tide violet amber fgDim;
  }));
in
{
  home.packages = [ helpManual ];
}

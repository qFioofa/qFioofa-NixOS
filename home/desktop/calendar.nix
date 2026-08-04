{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme)
    bg bgSurface fg fgDim fgMuted
    primary success warning error
    violet tide amber coral;

  calTheme = pkgs.replaceVars ./themes/calendar.rasi {
    inherit bg bgSurface fg fgDim fgMuted primary error;
  };

  calendar = pkgs.writeShellScriptBin "calendar" (builtins.readFile (pkgs.replaceVars ./scripts/calendar.sh {
    date = "${pkgs.coreutils}/bin/date";
    cal = "${pkgs.util-linux}/bin/cal";
    rofi = "${pkgs.rofi}/bin/rofi";
    sed = "${pkgs.gnused}/bin/sed";
    grep = "${pkgs.gnugrep}/bin/grep";
    calTheme = "${calTheme}";
    inherit fgMuted tide primary violet amber success coral warning;
  }));
in
{
  home.packages = [ calendar ];
}

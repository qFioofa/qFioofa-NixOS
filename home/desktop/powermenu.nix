{ pkgs, theme, ... }:
let
  inherit (theme)
    bg bgSurface fg fgDim fgMuted
    primary warning error
    violet tide amber;

  # A compact, centered rofi power menu — a small popup instead of the
  # fullscreen wlogout overlay. Each row is "<icon>  <label>".
  menuTheme = pkgs.replaceVars ./themes/powermenu.rasi {
    inherit bg bgSurface fg fgDim fgMuted primary error;
  };

  powermenu = pkgs.writeShellScriptBin "powermenu" (builtins.readFile (pkgs.replaceVars ./scripts/powermenu.sh {
    rofi = "${pkgs.rofi}/bin/rofi";
    menuTheme = "${menuTheme}";
    inherit tide amber violet warning error;
  }));
in
{
  home.packages = [ powermenu ];
}

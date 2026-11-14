{ config, pkgs, theme, ... }:
let
  inherit (theme)
    bg bgSurface fg fgDim fgMuted
    primary warning error
    violet tide amber coral
    radius radiusInner border font;

  rofi = "${config.programs.rofi.finalPackage}/bin/rofi";

  calTheme = pkgs.replaceVars ./themes/calendar.rasi {
    inherit bg bgSurface fg fgDim fgMuted primary error;
  };

  dateTools = pkgs.writeShellScriptBin "date-tools"
    (builtins.readFile (pkgs.replaceVars ./scripts/date-tools.sh {
      date = "${pkgs.coreutils}/bin/date";
      inherit rofi;
      sed = "${pkgs.gnused}/bin/sed";
      grep = "${pkgs.gnugrep}/bin/grep";
      wlcopy = "${pkgs.wl-clipboard}/bin/wl-copy";
      notify = "${pkgs.libnotify}/bin/notify-send";
      calTheme = "${calTheme}";
      inherit fgMuted tide primary violet amber coral warning;
    }));

  dateDayMenu = pkgs.writeShellScriptBin "date-day-menu"
    (builtins.readFile (pkgs.replaceVars ./scripts/date-day-menu.sh {
      date = "${pkgs.coreutils}/bin/date";
      inherit rofi;
      sed = "${pkgs.gnused}/bin/sed";
      wlcopy = "${pkgs.wl-clipboard}/bin/wl-copy";
      notify = "${pkgs.libnotify}/bin/notify-send";
      calTheme = "${calTheme}";
      dateTools = "${dateTools}/bin/date-tools";
      inherit fgMuted tide primary violet amber coral;
    }));

  themeRasi = pkgs.replaceVars ./naivecalendar/nixos.rasi {
    inherit bg bgSurface fg fgDim fgMuted primary violet;
    inherit radius radiusInner border font;
  };

  themeCfg = pkgs.replaceVars ./naivecalendar/nixos.cfg {
    inherit primary fgMuted;
  };

  customActions = pkgs.replaceVars ./naivecalendar/custom_actions.cfg {
    dateTools = "${dateTools}/bin/date-tools";
  };

  naivecalendar = pkgs.callPackage ./naivecalendar {
    rofi = config.programs.rofi.finalPackage;
    dayMenu = "${dateDayMenu}/bin/date-day-menu";
    inherit themeRasi themeCfg customActions;
  };

  calendar = pkgs.writeShellScriptBin "calendar" ''
    exec ${naivecalendar}/bin/naivecalendar "$@"
  '';
in
{
  home.packages = [ naivecalendar dateTools dateDayMenu calendar ];
}

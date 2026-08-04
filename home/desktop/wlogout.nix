{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme)
    bg
    bgSurface
    fg
    fgDim
    primary
    warning
    error
    tide
    violet
    font
    ;

  icons = "${pkgs.wlogout}/share/wlogout/icons";

  wlogout-toggle = pkgs.writeShellScriptBin "wlogout-toggle" (builtins.readFile (pkgs.replaceVars ./scripts/wlogout-toggle.sh {
    pgrep = "${pkgs.procps}/bin/pgrep";
    pkill = "${pkgs.procps}/bin/pkill";
    wlogout = "${pkgs.wlogout}/bin/wlogout";
  }));
in
{
  home.packages = [ wlogout-toggle ];

  programs.wlogout = {
    enable = true;

    # Severity ordering left to right: routine actions first, destructive
    # ones last. The keybind hint in each label aids discoverability.
    layout = [
      {
        label = "lock";
        action = "lock";
        text = "Lock (l)";
        keybind = "l";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend (s)";
        keybind = "s";
      }
      {
        label = "logout";
        action = "niri msg action quit --skip-confirmation";
        text = "Logout (e)";
        keybind = "e";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot (r)";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown (p)";
        keybind = "p";
      }
    ];

    style = builtins.readFile (pkgs.replaceVars ./themes/wlogout.css {
      inherit bg bgSurface fg fgDim primary warning error tide violet font icons;
      radius = theme.radius;
    });
  };
}

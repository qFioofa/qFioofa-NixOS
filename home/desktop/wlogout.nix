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

  # Toggle launcher: a second keypress closes the overlay instead of
  # stacking another instance. `-b 5` lays the five actions out as a single
  # centered row; the side margins keep the tiles from stretching edge to
  # edge on wide displays.
  wlogout-toggle = pkgs.writeShellScriptBin "wlogout-toggle" ''
    if ${pkgs.procps}/bin/pgrep -x wlogout >/dev/null; then
      ${pkgs.procps}/bin/pkill -x wlogout
    else
      exec ${pkgs.wlogout}/bin/wlogout -b 5 -T 360 -B 360 -L 80 -R 80
    fi
  '';
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

    style = ''
      @define-color bg ${bg};
      @define-color surface ${bgSurface};
      @define-color fg ${fg};
      @define-color fg_dim ${fgDim};
      @define-color primary ${primary};
      @define-color warning ${warning};
      @define-color error ${error};
      @define-color tide ${tide};
      @define-color violet ${violet};

      * {
        font-family: "${font}";
        font-size: 15px;
        font-weight: 500;
        background-image: none;
        box-shadow: none;
        transition: all 200ms cubic-bezier(0.33, 1, 0.68, 1);
      }

      /* Dim the desktop behind the overlay. */
      window {
        background-color: alpha(@bg, 0.92);
      }

      button {
        color: @fg_dim;
        background-color: alpha(@surface, 0.7);
        border: 2px solid alpha(@fg, 0.08);
        border-radius: ${theme.radius};
        margin: 16px;
        background-repeat: no-repeat;
        background-position: center 32%;
        background-size: 22%;
      }

      button:focus,
      button:hover {
        color: @fg;
        background-color: alpha(@surface, 0.95);
        background-size: 26%;
        outline: none;
      }

      /* Per-action accent: each tile glows in its own semantic colour on
         hover/focus so the destructive options read as more deliberate. */
      #lock {
        background-image: url("${icons}/lock.png");
      }
      #lock:focus,
      #lock:hover {
        color: @primary;
        border-color: @primary;
        box-shadow: 0 0 22px alpha(@primary, 0.3);
      }

      #suspend {
        background-image: url("${icons}/suspend.png");
      }
      #suspend:focus,
      #suspend:hover {
        color: @violet;
        border-color: @violet;
        box-shadow: 0 0 22px alpha(@violet, 0.3);
      }

      #logout {
        background-image: url("${icons}/logout.png");
      }
      #logout:focus,
      #logout:hover {
        color: @tide;
        border-color: @tide;
        box-shadow: 0 0 22px alpha(@tide, 0.3);
      }

      #reboot {
        background-image: url("${icons}/reboot.png");
      }
      #reboot:focus,
      #reboot:hover {
        color: @warning;
        border-color: @warning;
        box-shadow: 0 0 22px alpha(@warning, 0.3);
      }

      #shutdown {
        background-image: url("${icons}/shutdown.png");
      }
      #shutdown:focus,
      #shutdown:hover {
        color: @error;
        border-color: @error;
        box-shadow: 0 0 22px alpha(@error, 0.35);
      }
    '';
  };
}

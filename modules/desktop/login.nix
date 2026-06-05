{ pkgs, ... }:
let
  theme = import ../../theme.nix;

  loginUser = "qFioofa";
  defaultSession = "Niri";

  shellSession =
    (pkgs.writeTextDir "share/wayland-sessions/shell.desktop" ''
      [Desktop Entry]
      Name=Shell
      Comment=Fallback login shell on the bare TTY
      Exec=${pkgs.bashInteractive}/bin/bash -l
      Type=Application
      DesktopNames=Shell
    '').overrideAttrs
      (_: { passthru.providedSessions = [ "shell" ]; });

  defaultState = pkgs.writeText "regreet-state.toml" ''
    last_user = "${loginUser}"

    [user_to_last_sess]
    ${loginUser} = "${defaultSession}"
  '';

  yugenAshCss = ''
    @define-color yugen_bg ${theme.bg};
    @define-color yugen_surface ${theme.bgSurface};
    @define-color yugen_fg ${theme.fg};
    @define-color yugen_fg_dim ${theme.fgDim};
    @define-color yugen_fg_muted ${theme.fgMuted};
    @define-color yugen_primary ${theme.primary};
    @define-color yugen_error ${theme.error};

    window { background-color: transparent; }

    .background {
      background-color: alpha(@yugen_bg, 0.82);
      color: @yugen_fg;
      border: 1px solid alpha(@yugen_primary, 0.25);
      border-radius: 16px;
      padding: 22px;
      box-shadow: 0 10px 40px alpha(black, 0.55);
    }

    #message_label {
      color: @yugen_primary;
      font-weight: bold;
      font-size: 1.3em;
      margin-bottom: 6px;
    }

    #clock_frame label {
      color: @yugen_fg;
      font-size: 1.1em;
    }

    label { color: @yugen_fg_dim; }

    entry, passwordentry {
      background-color: alpha(@yugen_surface, 0.9);
      color: @yugen_fg;
      border: 1px solid alpha(@yugen_fg, 0.15);
      border-radius: 10px;
      caret-color: @yugen_primary;
      min-height: 34px;
    }
    entry:focus-within, passwordentry:focus-within {
      border-color: @yugen_primary;
      box-shadow: 0 0 0 2px alpha(@yugen_primary, 0.3);
    }

    dropdown, dropdown > button, combobox button {
      background-color: alpha(@yugen_surface, 0.9);
      color: @yugen_fg;
      border: 1px solid alpha(@yugen_fg, 0.15);
      border-radius: 10px;
    }

    button {
      border-radius: 10px;
      background-color: alpha(@yugen_surface, 0.9);
      color: @yugen_fg;
      border: 1px solid alpha(@yugen_fg, 0.1);
    }
    button:hover { background-color: alpha(@yugen_primary, 0.18); }

    button.suggested-action {
      background-color: @yugen_primary;
      color: @yugen_bg;
      font-weight: bold;
      border: none;
    }
    button.suggested-action:hover { background-color: shade(@yugen_primary, 1.08); }

    button.destructive-action {
      color: @yugen_error;
      background-color: alpha(@yugen_error, 0.12);
      border: 1px solid alpha(@yugen_error, 0.4);
    }
  '';
in
{
  services.greetd.enable = true;

  services.displayManager.sessionPackages = [ shellSession ];

  systemd.tmpfiles.settings."11-regreet-default"."/var/lib/regreet/state.toml"."C" = {
    mode = "0644";
    user = "greeter";
    group = "greeter";
    argument = "${defaultState}";
  };

  programs.regreet = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      package = pkgs.nerd-fonts.jetbrains-mono;
      size = 12;
    };

    extraCss = yugenAshCss;

    settings = {
      background = {
        path = ../../wallpaper/b-102.jpg;
        fit = "Cover";
      };
      GTK.application_prefer_dark_theme = true;

      skip_selection = false;

      appearance.greeting_msg = "welcome back";

      widget.clock = {
        format = "%A  ·  %d %B  ·  %H:%M";
        resolution = "1s";
      };
    };
  };
}

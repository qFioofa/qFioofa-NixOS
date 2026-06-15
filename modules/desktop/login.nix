{ pkgs, inputs, ... }:
let
  theme = import ../../theme.nix;

  # regreet pinned to 0.3.0 from nixpkgs-regreet (see flake.nix). 0.4.0 is a
  # breaking release that crash-loops the greeter; keep this off the main
  # nixpkgs input so `nix flake update` can't bump it.
  pkgsRegreet = inputs.nixpkgs-regreet.legacyPackages.${pkgs.system};

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

  # Pre-process the wallpaper at build time: fill the screen, soften it with a
  # light blur, and dim it ~35% so the login card and clock stay readable no
  # matter how busy the source image is. ReGreet can't blur/dim on its own.
  dimmedBackground = pkgs.runCommand "regreet-bg.jpg" { } ''
    ${pkgs.imagemagick}/bin/magick ${../../wallpaper/b-102.jpg} \
      -resize 1920x1080^ -gravity center -extent 1920x1080 \
      -blur 0x4 \
      -fill black -colorize 32% \
      -quality 92 $out
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
      background-color: alpha(@yugen_bg, 0.78);
      color: @yugen_fg;
      border: 1px solid alpha(@yugen_primary, 0.22);
      border-radius: 18px;
      padding: 26px 30px;
      box-shadow: 0 18px 60px alpha(black, 0.6);
    }

    #message_label {
      color: @yugen_primary;
      font-weight: bold;
      font-size: 1.35em;
      margin-bottom: 8px;
    }

    /* Hero clock: large time, the date/format string reads as a quiet caption. */
    #clock_frame label {
      color: @yugen_fg;
      font-size: 2.4em;
      font-weight: 300;
      letter-spacing: 1px;
      margin-bottom: 14px;
    }

    label { color: @yugen_fg_dim; }

    entry, passwordentry {
      background-color: alpha(@yugen_surface, 0.9);
      color: @yugen_fg;
      border: 1px solid alpha(@yugen_fg, 0.15);
      border-radius: 10px;
      caret-color: @yugen_primary;
      min-height: 36px;
      transition: border-color 150ms ease, box-shadow 150ms ease;
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
      transition: background-color 150ms ease, border-color 150ms ease;
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
    package = pkgsRegreet.regreet;

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
        path = dimmedBackground;
        fit = "Cover";
      };
      GTK.application_prefer_dark_theme = true;

      # Skip the user/session picker and jump straight to the password field
      # using the remembered session (defaultState pins Niri). One less click.
      skip_selection = true;

      appearance.greeting_msg = "welcome back";

      widget.clock = {
        format = "%A  ·  %d %B  ·  %H:%M";
        resolution = "1s";
      };
    };
  };
}

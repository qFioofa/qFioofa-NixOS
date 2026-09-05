{ pkgs, inputs, theme, ... }:
let
  # regreet pinned to 0.3.0 from nixpkgs-regreet (see flake.nix). 0.4.0 is a
  # breaking release that crash-loops the greeter; keep this off the main
  # nixpkgs input so `nix flake update` can't bump it.
  pkgsRegreet = inputs.nixpkgs-regreet.legacyPackages.${pkgs.stdenv.hostPlatform.system};

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
    ${pkgs.imagemagick}/bin/magick ${theme.wallpaper} \
      -resize 1920x1080^ -gravity center -extent 1920x1080 \
      -blur 0x4 \
      -fill black -colorize 32% \
      -quality 92 $out
  '';

  yugenAshCss = builtins.readFile (pkgs.replaceVars ./themes/regreet.css {
    inherit (theme) bg bgSurface fg fgDim fgMuted primary error;
  });
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
      name = "Nordzy-catppuccin-latte-peach";
      package = pkgs.nordzy-cursor-theme;
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

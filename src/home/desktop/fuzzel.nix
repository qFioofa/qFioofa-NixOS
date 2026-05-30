{ ... }: {
  # ── Application launcher (fuzzel) ─────────────────────────────────────
  # Native-Wayland launcher, rendered dead-center by default. Opened by Mod+D
  # and by tapping the Win key (F13 via keyd, see modules/desktop/keyd.nix).
  #
  # Chosen over rofi: rofi has no reliable native-Wayland backend on niri (the
  # `rofi-wayland` fork mishandles the wl_keyboard protocol and drops input on
  # niri), whereas fuzzel is wlroots/niri-native and needs no XWayland.
  #
  # Config maps 1:1 to fuzzel.ini(5). Colors are RRGGBBAA hex WITHOUT a leading
  # '#'. `prompt` keeps its trailing space via embedded quotes (the ini parser
  # would otherwise strip it). Booleans are written as yes/no strings.
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font           = "JetBrainsMono Nerd Font:size=12";
        prompt         = "\"❯ \"";
        icon-theme     = "Papirus-Dark";
        icons-enabled  = "yes";
        # $TERMINAL is "terminal" (the launcher script in apps/terminals); -e
        # runs a command in it, so terminal-spawning .desktop entries work.
        terminal       = "terminal -e";
        layer          = "overlay";
        anchor         = "center";   # dead-center on screen (also the default)
        width          = 35;
        lines          = 10;
        horizontal-pad = 20;
        vertical-pad   = 14;
        inner-pad      = 10;
      };

      border = {
        width  = 2;
        radius = 12;
      };

      # yugen-ash palette — keep in sync with niri.nix / waybar / terminals.
      colors = {
        background      = "151515f5";
        text            = "d4d4d4ff";
        prompt          = "ffbe89ff";
        placeholder     = "696969ff";
        input           = "d4d4d4ff";
        match           = "ffbe89ff";
        selection       = "303030ff";
        selection-text  = "ffbe89ff";
        selection-match = "ff9e8bff";
        counter         = "696969ff";
        border          = "ffbe89ff";
      };
    };
  };
}

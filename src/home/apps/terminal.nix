{ pkgs, ... }:
let
  # ─── yugen-ash (main variant) ────────────────────────────────────────────
  # https://github.com/qFioofa/yugen-ash.nvim — warm "ash" dark palette.
  c = {
    bg       = "#151515"; # color700
    bgAlt    = "#000000"; # color800
    surface  = "#303030"; # color600
    overlay  = "#505050"; # color500
    muted    = "#696969"; # color400
    subtext  = "#A9A9A9"; # color300
    fg       = "#D4D4D4"; # color200
    fgBright = "#FAFAFA"; # color100

    primary  = "#FFBE89"; # accent / cursor
    red      = "#F57A7A"; # error
    green    = "#7EAB8E"; # success
    yellow   = "#FFF2AF"; # warning
    blue     = "#79A0AA"; # tide
    magenta  = "#C678DD"; # violet
    cyan     = "#8DD3C3"; # seafoam
    white    = "#D4D4D4";

    brRed     = "#FF9E8B"; # coral
    brGreen   = "#9DB89C"; # sage
    brYellow  = "#D4A76A"; # amber
    brBlue    = "#96A8AD"; # frost
    brMagenta = "#C678DD";
    brCyan    = "#8DD3C3";
    brWhite   = "#FAFAFA";
  };

  font    = "JetBrainsMono Nerd Font Mono";
  opacity = 0.95;

  # 16-colour ANSI palette in canonical order (black, red, … bright white).
  ansi = [
    c.bg c.red c.green c.yellow c.blue c.magenta c.cyan c.white
    c.muted c.brRed c.brGreen c.brYellow c.brBlue c.brMagenta c.brCyan c.brWhite
  ];

  # Strip the leading '#' (foot wants bare 6-digit hex).
  bare = s: builtins.substring 1 6 s;

  # ─── Fallback launcher ────────────────────────────────────────────────────
  # `terminal` execs the first terminal that is actually installed. ghostty is
  # the preferred default; the rest are graceful fallbacks. Used by niri's
  # Mod+Return and by $TERMINAL so anything that shells out to a terminal works.
  terminalLauncher = pkgs.writeShellScriptBin "terminal" ''
    for t in ghostty wezterm alacritty foot kitty xterm; do
      if command -v "$t" >/dev/null 2>&1; then
        exec "$t" "$@"
      fi
    done
    echo "terminal: no supported terminal emulator found" >&2
    exit 127
  '';
in {
  home.packages = [ terminalLauncher pkgs.wezterm ];
  home.sessionVariables.TERMINAL = "terminal";

  # ─── ghostty (default) ────────────────────────────────────────────────────
  programs.ghostty = {
    enable = true;
    settings = {
      font-family       = font;
      font-size         = 12;
      background        = c.bg;
      foreground        = c.fgBright;
      cursor-color      = c.primary;
      cursor-text       = c.bg;
      selection-background = c.surface;
      selection-foreground = c.fgBright;
      background-opacity = opacity;
      window-padding-x  = 10;
      window-padding-y  = 10;
      window-decoration = false;
      cursor-style      = "block";
      palette = builtins.genList
        (i: "${toString i}=${builtins.elemAt ansi i}")
        (builtins.length ansi);
    };
  };

  # ─── alacritty (fallback) ─────────────────────────────────────────────────
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity     = opacity;
        padding     = { x = 10; y = 10; };
        decorations = "none";
      };
      font = {
        normal.family = font;
        size          = 12.0;
      };
      colors = {
        primary   = { background = c.bg; foreground = c.fgBright; };
        cursor    = { cursor = c.primary; text = c.bg; };
        selection = { background = c.surface; text = c.fgBright; };
        normal = {
          black = c.bg;  red = c.red;     green = c.green;   yellow = c.yellow;
          blue  = c.blue; magenta = c.magenta; cyan = c.cyan; white = c.white;
        };
        bright = {
          black = c.muted; red = c.brRed;   green = c.brGreen; yellow = c.brYellow;
          blue  = c.brBlue; magenta = c.brMagenta; cyan = c.brCyan; white = c.brWhite;
        };
      };
    };
  };

  # ─── foot (lightweight wayland fallback) ──────────────────────────────────
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "${font}:size=12";
        pad  = "10x10";
      };
      colors = {
        alpha      = opacity;
        background = bare c.bg;
        foreground = bare c.fgBright;
        regular0 = bare c.bg;     regular1 = bare c.red;     regular2 = bare c.green;
        regular3 = bare c.yellow; regular4 = bare c.blue;    regular5 = bare c.magenta;
        regular6 = bare c.cyan;   regular7 = bare c.white;
        bright0  = bare c.muted;  bright1  = bare c.brRed;   bright2  = bare c.brGreen;
        bright3  = bare c.brYellow; bright4 = bare c.brBlue; bright5  = bare c.brMagenta;
        bright6  = bare c.brCyan; bright7  = bare c.brWhite;
      };
      cursor.color = "${bare c.bg} ${bare c.primary}";
    };
  };

  # ─── wezterm (fallback) ───────────────────────────────────────────────────
  # Written as a raw config file to stay independent of HM module quirks.
  xdg.configFile."wezterm/wezterm.lua".text = ''
    local wezterm = require 'wezterm'
    return {
      font = wezterm.font '${font}',
      font_size = 12.0,
      window_background_opacity = ${toString opacity},
      window_padding = { left = 10, right = 10, top = 10, bottom = 10 },
      window_decorations = 'NONE',
      hide_tab_bar_if_only_one_tab = true,
      colors = {
        foreground   = '${c.fgBright}',
        background   = '${c.bg}',
        cursor_bg    = '${c.primary}',
        cursor_fg    = '${c.bg}',
        cursor_border = '${c.primary}',
        selection_bg = '${c.surface}',
        selection_fg = '${c.fgBright}',
        ansi    = { '${c.bg}', '${c.red}', '${c.green}', '${c.yellow}', '${c.blue}', '${c.magenta}', '${c.cyan}', '${c.white}' },
        brights = { '${c.muted}', '${c.brRed}', '${c.brGreen}', '${c.brYellow}', '${c.brBlue}', '${c.brMagenta}', '${c.brCyan}', '${c.brWhite}' },
      },
    }
  '';
}

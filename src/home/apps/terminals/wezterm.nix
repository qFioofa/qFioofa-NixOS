{ ... }:
let
  inherit (import ./palette.nix) c font opacity;
in {
  # wezterm (fallback) — raw config file to stay independent of HM module
  # quirks. Package comes from ./default.nix's home.packages.
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

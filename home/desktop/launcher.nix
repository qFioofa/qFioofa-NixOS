{ pkgs, lib, theme, ... }:
let
  inherit (theme) bg bgSurface fg fgDim fgMuted primary radius radiusInner border font;
  mkL = value: { _type = "literal"; inherit value; };
  # Generates override .desktop entries with a Cyrillic key-position keyword so
  # the Apps search matches Latin-named apps typed on the RU layout. See script.
  rofiTranslit = pkgs.writeShellScriptBin "rofi-translit"
    (builtins.readFile (pkgs.replaceVars ./scripts/rofi-translit.sh {
      perl = "${pkgs.perl}/bin/perl";
    }));
in
{
  home.packages = [ rofiTranslit ];
  home.activation.rofiTranslit =
    lib.hm.dag.entryAfter [ "writeBoundary" ] "run ${rofiTranslit}/bin/rofi-translit || true";

  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    # calc → math in the launcher; emoji → searchable emoji picker (Mod+Period).
    # Loaded into the wrapped finalPackage that the niri binds spawn.
    plugins = [ pkgs.rofi-calc pkgs.rofi-emoji ];
    terminal = "foot";
    font = "${font} 12";
    extraConfig = {
      # Tabs in order (Alt+Right / Alt+Left or click to cycle):
      #   Apps   — plain app launch (default, what Mod+D opens)
      #   Apps + — combi: run-commands + files (NOT apps — keeps it distinct
      #            from the Apps tab; adding drun here just duplicates Apps)
      #   Emoji  — emoji picker
      #   Run    — console programs
      #   Calc   — calculator
      modi = "drun,combi,emoji,run,calc";
      combi-modi = "run,filebrowser";
      # Cycle tabs with Alt+Right / Alt+Left (Ctrl+Tab default was unreliable).
      # Tab keeps its default next-item role.
      kb-mode-next = "Alt+Right";
      kb-mode-previous = "Alt+Left";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      display-drun = " Apps";
      display-combi = " Apps +";
      display-emoji = " Emoji";
      display-run = " Run";
      display-calc = " Calc";
      display-filebrowser = " Files";
      drun-display-format = "{name}";
      # Match apps by every field (name, generic name, exec, categories,
      # keywords, comment) so e.g. "browser" finds Firefox; show .desktop
      # actions like "New Private Window" as their own entries.
      drun-match-fields = "all";
      # Off: hides .desktop actions ("Firefox – New Window") from the Apps
      # list. rofi only exposes this globally, so it's all-or-nothing across
      # every drun view — can't isolate the actions into the Apps + tab.
      drun-show-actions = false;
      matching = "fuzzy";
      sort = true;
      sorting-method = "fzf";
      scroll-method = 0;
      click-to-exit = true;
    };
    theme =
      {
        "*" = {
          bg = mkL bg;
          bg-surface = mkL bgSurface;
          fg = mkL fg;
          fg-dim = mkL fgDim;
          fg-muted = mkL fgMuted;
          accent = mkL primary;
          background-color = mkL "transparent";
          text-color = mkL "@fg";
        };
        window = {
          width = mkL "35%";
          padding = mkL "0";
          border = mkL border;
          border-color = mkL "@accent";
          border-radius = mkL radius;
          background-color = mkL "@bg";
        };
        mainbox = {
          spacing = mkL "8px";
          padding = mkL "16px";
          background-color = mkL "transparent";
          # search bar → visible category tabs → results list.
          children = mkL "[ inputbar, mode-switcher, listview ]";
        };
        inputbar = {
          spacing = mkL "8px";
          padding = mkL "10px 12px";
          border-radius = mkL radiusInner;
          background-color = mkL "@bg-surface";
          children = mkL "[prompt, entry]";
        };
        prompt = {
          padding = mkL "0 4px 0 0";
          text-color = mkL "@accent";
        };
        entry = {
          placeholder = mkL ''"Search..."'';
          placeholder-color = mkL "@fg-muted";
          text-color = mkL "@fg";
        };
        # Visible category tabs (Apps / Apps + / Emoji / Run / Calc). The
        # buttons are the display-<modi> names from extraConfig; the active mode
        # is highlighted. Click a tab or use Ctrl+Tab to switch.
        "mode-switcher" = {
          spacing = mkL "8px";
          background-color = mkL "transparent";
        };
        button = {
          padding = mkL "8px 12px";
          border-radius = mkL radiusInner;
          background-color = mkL "@bg-surface";
          text-color = mkL "@fg-dim";
          cursor = mkL "pointer";
        };
        "button selected" = {
          background-color = mkL "@accent";
          text-color = mkL "@bg";
        };
        listview = {
          lines = mkL "8";
          spacing = mkL "4px";
          padding = mkL "4px 0 0 0";
          scrollbar = mkL "false";
          background-color = mkL "transparent";
        };
        element = {
          padding = mkL "8px 12px";
          spacing = mkL "8px";
          border-radius = mkL radiusInner;
          background-color = mkL "transparent";
          text-color = mkL "@fg-dim";
        };
        "element selected" = {
          background-color = mkL "@bg-surface";
          text-color = mkL "@accent";
        };
        "element-icon" = {
          size = mkL "24px";
          text-color = mkL "inherit";
        };
        "element-text" = {
          text-color = mkL "inherit";
          highlight = mkL "bold underline";
        };
      };
  };
}

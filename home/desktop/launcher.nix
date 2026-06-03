{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "foot";
    font = "JetBrainsMono Nerd Font 12";
    extraConfig = {
      modi = "drun,run,filebrowser";
      show-icons = true;
      display-drun = " Apps";
      display-run = " Run";
      display-filebrowser = " Files";
      drun-display-format = "{name}";
      matching = "fuzzy";
      sort = true;
      sorting-method = "fzf";
      scroll-method = 0;
      click-to-exit = true;
    };
    theme =
      let
        mkL = value: { _type = "literal"; inherit value; };
      in
      {
        "*" = {
          bg = mkL "#151515";
          bg-surface = mkL "#303030";
          fg = mkL "#D4D4D4";
          fg-dim = mkL "#A9A9A9";
          fg-muted = mkL "#696969";
          accent = mkL "#FFBE89";
          background-color = mkL "transparent";
          text-color = mkL "@fg";
        };
        window = {
          width = mkL "35%";
          padding = mkL "0";
          border = mkL "2px";
          border-color = mkL "@accent";
          border-radius = mkL "12px";
          background-color = mkL "@bg";
        };
        mainbox = {
          spacing = mkL "8px";
          padding = mkL "16px";
          background-color = mkL "transparent";
        };
        inputbar = {
          spacing = mkL "8px";
          padding = mkL "10px 12px";
          border-radius = mkL "8px";
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
          border-radius = mkL "8px";
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

{ pkgs, ... }: {
  home.packages = [ pkgs.rofi ];

  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      modi:        "drun,run";
      show-icons:  true;
      location:    0;
    }
    @theme "~/.config/rofi/theme.rasi"
  '';

  xdg.configFile."rofi/theme.rasi".text = ''
    * {
      bg:      #1e1e2e;
      bg-alt:  #313244;
      fg:      #cdd6f4;
      accent:  #cba6f7;
      border:  #cba6f7;
    }
    window   { background-color: @bg; border: 2px; border-color: @border; border-radius: 10px; width: 500px; }
    mainbox  { background-color: @bg; padding: 8px; }
    inputbar { background-color: @bg-alt; border-radius: 6px; padding: 8px 14px; margin-bottom: 8px; }
    entry    { background-color: transparent; text-color: @fg; placeholder-color: #6c7086; }
    prompt   { background-color: transparent; text-color: @accent; padding-right: 8px; }
    listview { background-color: transparent; lines: 8; scrollbar: false; }
    element  { background-color: transparent; padding: 6px 14px; border-radius: 6px; }
    element.selected.normal { background-color: @bg-alt; text-color: @accent; }
    element-text { background-color: transparent; text-color: inherit; }
    element-icon { background-color: transparent; size: 20px; }
  '';
}

{ ... }:
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=11";
        terminal = "foot";
      };
      colors = {
        background = "1e1e2eff";
        text = "cdd6f4ff";
        selection = "7aa2f7ff";
        selection-text = "1e1e2eff";
        border = "7aa2f7ff";
      };
    };
  };
}

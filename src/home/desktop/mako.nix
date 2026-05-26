{ ... }: {
  services.mako = {
    enable          = true;
    font            = "JetBrainsMono Nerd Font Mono 11";
    width           = 380;
    borderRadius    = 8;
    borderSize      = 2;
    defaultTimeout  = 5000;
    backgroundColor = "#1e1e2e";
    textColor       = "#cdd6f4";
    borderColor     = "#cba6f7";

    extraConfig = ''
      [urgency=low]
      border-color=#89b4fa

      [urgency=high]
      border-color=#f38ba8
      default-timeout=0
    '';
  };
}

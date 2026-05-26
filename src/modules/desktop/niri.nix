{ pkgs, ... }: {
  programs.niri.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL   = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "niri";
  };

  environment.systemPackages = [ pkgs.swaybg ];
}

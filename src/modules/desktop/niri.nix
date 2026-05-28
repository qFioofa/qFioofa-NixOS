{ pkgs, ... }: {
  programs.niri.enable = true;

  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.sddm.wayland.sessionPackages = [ pkgs.niri ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL   = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "niri";
  };

  environment.systemPackages = [ pkgs.swaybg ];
}

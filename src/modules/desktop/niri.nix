{ pkgs, ... }: {
  programs.niri.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL      = "1";
    XDG_SESSION_TYPE    = "wayland";
    XDG_CURRENT_DESKTOP = "niri";
  };

  # swaylock authenticates against a PAM service literally named "swaylock".
  # When swaylock comes from home-manager (not programs.sway), that service is
  # NOT created automatically, so the lock screen can never verify the password
  # and you get locked out. This declares it (empty set = sane defaults).
  security.pam.services.swaylock = {};

  # gnome-keyring stores secrets/SSH keys and is what the GNOME portal and many
  # GUI apps expect for the org.freedesktop.secrets service. Unlocked on login.
  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = [ pkgs.swaybg ];
}

{ pkgs, lib, ... }:
{

  services.swayosd = {
    enable = true;
    stylePath = ./themes/swayosd-style.css;
  };

  # swayosd's generated unit races niri's startup: it is WantedBy
  # graphical-session.target with ConditionEnvironment=WAYLAND_DISPLAY, but at
  # that point niri has not yet exported the display to the user manager, so
  # the condition fails and the OSD server is skipped ("start condition unmet")
  # — leaving the volume/brightness binds with no server to act on. niri now
  # spawns swayosd-server itself (see desktop/niri.nix), so stop the unit from
  # being pulled in at all.
  systemd.user.services.swayosd = {
    Unit.ConditionEnvironment = lib.mkForce [ ];
    Install.WantedBy = lib.mkForce [ ];
  };

  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "laptop";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            scale = 1.0;
          }
        ];
      }
      {
        profile.name = "docked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "disable";
          }
          {
            criteria = "HDMI-A-1";
            status = "enable";
            position = "0,0";
          }
        ];
      }
    ];
  };

  services.network-manager-applet.enable = true;

  # Keep blueman-manager available for the waybar bluetooth module, but stop the
  # tray applet from auto-starting. A user-level Hidden autostart entry overrides
  # the system blueman.desktop, so systemd's xdg-autostart generator skips it
  # (no more app-blueman@autostart at login).
  xdg.configFile."autostart/blueman.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';
}

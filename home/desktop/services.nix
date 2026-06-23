{ pkgs, ... }:
{

  services.swayosd = {
    enable = true;
    stylePath = ./themes/swayosd-style.css;
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

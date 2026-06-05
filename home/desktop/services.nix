{ pkgs, ... }:
{

  services.swayosd = {
    enable = true;
    stylePath = pkgs.writeText "swayosd-style.css" ''
      window {
        background: rgba(21, 21, 21, 0.92);
        border: 2px solid #303030;
        border-radius: 12px;
      }
      #container {
        margin: 14px;
      }
      image,
      label {
        color: #D4D4D4;
      }
      progressbar {
        min-height: 6px;
        border-radius: 999px;
        background: #303030;
      }
      progressbar progress {
        border-radius: 999px;
        background: #FFBE89;
      }
    '';
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
}

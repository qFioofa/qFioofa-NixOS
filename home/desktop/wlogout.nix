{ pkgs, ... }:
{
  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "lock";
        action = "swaylock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "niri msg action quit --skip-confirmation";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "s";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "p";
      }
    ];

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
        background-image: none;
        transition: all 0.2s ease;
      }

      window {
        background: rgba(21, 21, 21, 0.92);
      }

      button {
        color: #D4D4D4;
        background-color: #303030;
        border: 2px solid #303030;
        border-radius: 16px;
        margin: 14px;
        background-repeat: no-repeat;
        background-position: center;
        background-size: 28%;
      }

      button:focus,
      button:hover {
        color: #FFBE89;
        background-color: #1f1f1f;
        border-color: #FFBE89;
        outline: none;
      }

      #lock {
        background-image: url("${pkgs.wlogout}/share/wlogout/icons/lock.png");
      }
      #logout {
        background-image: url("${pkgs.wlogout}/share/wlogout/icons/logout.png");
      }
      #suspend {
        background-image: url("${pkgs.wlogout}/share/wlogout/icons/suspend.png");
      }
      #reboot {
        background-image: url("${pkgs.wlogout}/share/wlogout/icons/reboot.png");
      }
      #shutdown {
        background-image: url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png");
      }
    '';
  };
}

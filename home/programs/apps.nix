{ pkgs, ... }:
let
  gnomeSettings = pkgs.symlinkJoin {
    name = "gnome-control-center-wrapped";
    paths = [ pkgs.gnome-control-center ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/gnome-control-center \
        --set XDG_CURRENT_DESKTOP GNOME

      rm -f $out/share/applications/org.gnome.Settings.desktop
      sed '/^OnlyShowIn=/d' \
        ${pkgs.gnome-control-center}/share/applications/org.gnome.Settings.desktop \
        > $out/share/applications/org.gnome.Settings.desktop
    '';
  };
in
{
  home.packages = with pkgs; [
    vlc
    nemo
    chromium
    telegram-desktop
    rocketchat-desktop
    networkmanagerapplet

    gimp
    discord
    zoom-us

    virtualbox

    gnomeSettings
    mission-center
  ];

  dconf.settings."org/nemo/preferences".show-location-entry = true;
}

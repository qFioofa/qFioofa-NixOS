{ pkgs, ... }:
let
  # gnome-control-center 50 hard-exits with "only supported under GNOME and
  # Unity" unless XDG_CURRENT_DESKTOP contains GNOME/Unity. niri sets it to
  # "niri", and overriding it globally would misroute xdg-desktop-portal, so we
  # force the variable for this app alone via a wrapper. We also strip
  # OnlyShowIn=GNOME from its launcher entry so it still appears in rofi (which
  # honours OnlyShowIn and would otherwise hide "Settings").
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

    # Settings / system info, since niri ships no control center of its own.
    # gnome-control-center IS GNOME Settings (same libadwaita UI). Under niri the
    # hardware-ish panels (Network, Bluetooth, Sound, Power, Users, Date & Time,
    # Region, About) work; session panels (Displays, Appearance, Multitasking)
    # need a GNOME session and stay inert. We deliberately do NOT enable
    # gnome-settings-daemon — its media-keys/power daemons would fight niri's own
    # brightness/volume handling. Wrapped (see `gnomeSettings` above) so it runs
    # outside a GNOME session.
    gnomeSettings
    # Mission Center: libadwaita system monitor (CPU/RAM/GPU/disk/net/processes).
    mission-center
  ];

  # nemo keyboard navigation. Type-ahead-to-select (start typing a name in the
  # file list and nemo jumps to the match) is the built-in default in nemo 6.6.4
  # and has no gsettings toggle — it already works. What we add here is the
  # always-visible editable location bar, so a path can be typed straight from
  # the keyboard instead of having to hit Ctrl+L first.
  dconf.settings."org/nemo/preferences".show-location-entry = true;
}

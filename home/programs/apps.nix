{ pkgs, lib, ... }:
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

  # Nemo plus the extensions that add the "missing" file-manager features:
  #   • fileroller — create/extract archives from the right-click menu
  #   • preview    — Spacebar quick-look for images/text/PDF/video (GNOME Sushi-like)
  #   • emblems    — tag files with emblem icons
  #   • seahorse   — GPG sign/encrypt from the context menu
  #   • python     — runtime other python extensions load against
  nemo = pkgs.nemo-with-extensions.override {
    extensions = with pkgs; [
      nemo-fileroller
      nemo-preview
      nemo-emblems
      nemo-seahorse
      nemo-python
    ];
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

  dconf.settings = {
    "org/nemo/preferences" = {
      show-location-entry = true;         # editable path bar instead of breadcrumbs
      default-folder-viewer = "list-view";
      show-full-path-titles = true;       # full path in the window title
      date-format = "informal";           # "Yesterday 14:03" style
      size-prefixes = "base-10";          # MB, not MiB
      show-image-thumbnails = "always";   # thumbnail files on network mounts too
      show-hidden-files = false;          # Ctrl+H still toggles per-session
      click-policy = "double";
      start-with-dual-pane = false;       # F3 splits when you want it
      thumbnail-limit = lib.hm.gvariant.mkUint64 104857600;  # thumbnail files up to 100 MB
      tooltips-in-icon-view = true;
      tooltips-in-list-view = true;
      show-directory-item-counts = "always";
    };
    # Right-click menu: surface the useful-but-hidden actions.
    "org/nemo/preferences/menu-config" = {
      selection-menu-make-link = true;
      selection-menu-copy-to = true;
      selection-menu-move-to = true;
      selection-menu-open-in-new-tab = true;
    };
    "org/nemo/list-view" = {
      default-visible-columns = [ "name" "size" "type" "date_modified" ];
      default-column-order = [ "name" "size" "type" "date_modified" "date_created" "permissions" ];
      default-zoom-level = "small";
    };
    # Terminal that "Open in Terminal" launches (Nemo reads this Cinnamon key).
    "org/cinnamon/desktop/applications/terminal" = {
      exec = "ghostty";
      exec-arg = "-e";
    };
  };
}

{ pkgs, lib, ... }:
let
  # Map every mime type in the list to the same .desktop handler.
  forAll = types: app: lib.genAttrs types (_: app);
in
{
  home.packages = with pkgs; [
    loupe    # images  (GNOME's Wayland-native viewer)
    evince   # PDFs / documents
    # vlc for video/audio is already installed in apps.nix
  ];

  # File associations — what double-clicking in Nemo (and `xdg-open`) launches.
  # `enable`/mimeApps is turned on in firefox.nix; these keys merge into it.
  xdg.mimeApps.defaultApplications =
    forAll [
      "image/png" "image/jpeg" "image/gif" "image/webp" "image/bmp"
      "image/tiff" "image/svg+xml" "image/x-icon" "image/heif" "image/avif"
    ] "org.gnome.Loupe.desktop"
    // forAll [
      "video/mp4" "video/x-matroska" "video/webm" "video/quicktime"
      "video/x-msvideo" "video/mpeg" "video/x-flv" "video/3gpp"
      "audio/mpeg" "audio/flac" "audio/x-wav" "audio/ogg" "audio/mp4"
      "audio/aac" "audio/x-m4a"
    ] "vlc.desktop"
    // {
      "application/pdf" = "org.gnome.Evince.desktop";
    };
}

{ ... }:
{
  # Disable middle-click (primary-selection) paste. Pressing the mouse wheel
  # otherwise pastes the primary selection into GTK widgets; gtk-enable-primary-
  # paste = false turns that off. niri has no compositor-level toggle for this,
  # so it is done per toolkit. Written to ~/.config/gtk-{3,4}.0/settings.ini.
  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-enable-primary-paste = false;
    gtk4.extraConfig.gtk-enable-primary-paste = false;
  };
}

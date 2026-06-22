{ ... }:
{
  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-enable-primary-paste = false;
    gtk4.extraConfig.gtk-enable-primary-paste = false;
  };
}

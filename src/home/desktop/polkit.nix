{ ... }: {
  # ── Polkit authentication agent ───────────────────────────────────────
  # niri does not start a polkit agent itself. Without one, any GUI action
  # that needs elevated privileges (blueman pairing, mounting disks, some
  # NetworkManager prompts) silently fails because there is nothing to show
  # the authentication dialog. The GNOME agent matches our GNOME portal/keyring
  # choice. It runs as a user service bound to graphical-session.target, which
  # the niri session starts — so it comes up automatically on login.
  services.polkit-gnome.enable = true;
}

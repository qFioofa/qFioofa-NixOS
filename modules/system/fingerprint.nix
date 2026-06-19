{ ... }:
{
  # Fingerprint authentication via fprintd (libfprint).
  #
  # Enabling fprintd flips the NixOS default of `security.pam.services.<name>.
  # fprintAuth` to true for *every* PAM service, so a fingerprint becomes a
  # `sufficient` auth step ahead of the password on all of them. That single
  # switch wires up exactly the surfaces we want:
  #   • login    — the greetd/regreet PAM service (modules/desktop/login.nix)
  #   • lock     — swaylock / swaylock-plugin (modules/desktop/niri.nix); their
  #                fprintAuth also defaults to true, so the existing custom auth
  #                rules keep working and a finger now unlocks the screen
  #   • sudo     — terminal privilege escalation
  #   • polkit-1 — GUI authentication agent prompts
  #
  # PAM tries the finger first (you may scan instead of typing); a wrong/missing
  # scan falls through to the normal password, so nothing is locked out.
  #
  # A reader still has to exist and be enrolled before any of this does anything:
  #   fprintd-enroll        # scan a finger (repeat for more)
  #   fprintd-verify        # confirm it reads back
  #   fprintd-list "$USER"  # show enrolled prints
  # If `fprintd-enroll` reports "No devices available", libfprint has no driver
  # for this laptop's sensor and fingerprint auth can't work regardless of config.
  services.fprintd.enable = true;
}

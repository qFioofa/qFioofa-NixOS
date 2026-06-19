{ pkgs, ... }:
let
  # Console password feedback for the lock screen (see home/desktop/lock.nix).
  # swaylock-plugin owns the keyboard grab, so the lock's tmux panes can never
  # see keystrokes directly. Instead we hook swaylock-plugin's PAM stack with
  # pam_exec: on every password submit it runs this script, which reads ONLY the
  # length of the typed password (via expose_authtok on stdin) and appends
  # "<epoch> <len>" to a per-user state file. The lock's feedback pane tails that
  # file to draw the password mask and the failed-attempt counter. The password
  # itself is never stored, logged, or written anywhere — only its length. The
  # rule is `optional`, so this script's exit status can never block or fail an
  # unlock, and it appends to a plain file (never a FIFO) so it can never hang.
  lockFeedbackHook = pkgs.writeShellScript "lock-feedback-hook" ''
    dir="/run/user/$(${pkgs.coreutils}/bin/id -u)"
    [ -d "$dir" ] || exit 0
    IFS= read -r pw 2>/dev/null || true
    len=''${#pw}
    pw=
    printf '%s %s\n' "$(${pkgs.coreutils}/bin/date +%s)" "$len" \
      >> "$dir/lock-feedback" 2>/dev/null || true
    exit 0
  '';
in
{
  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    # niri ships a portals.conf that defaults FileChooser to the gnome backend,
    # which delegates to nautilus. We use nemo, so route the file picker (and
    # everything else) to the gtk backend explicitly — otherwise save/download
    # dialogs in Firefox/Chromium silently never appear.
    #
    # ScreenCast/ScreenShot, however, are *not* implemented by the gtk backend.
    # niri's screen sharing is served by the gnome backend, so route those two
    # interfaces to gnome explicitly — otherwise the screen-share picker never
    # appears in Firefox/Chromium and sharing silently fails.
    config.common = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      "org.freedesktop.impl.portal.ScreenShot" = [ "gnome" ];
    };
  };

  security.polkit.enable = true;

  # GSettings backend for GTK apps. Required for the home-manager `dconf.settings`
  # we use to configure nemo (see home/programs/apps.nix) to actually take effect.
  programs.dconf.enable = true;

  # File-manager backends for nemo. niri ships no desktop environment, so none
  # of these come in by default and nemo silently loses core features:
  #   • gvfs    — the trash:// backend (Del → "move to trash" no-ops without it),
  #               plus network shares, MTP/phones and the "Other Locations" view.
  #   • udisks2 — mounting/unmounting removable drives from the sidebar.
  #   • tumbler — thumbnails for images/videos/PDFs in the file list.
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;

  # Allow the lock screen to authenticate the user (otherwise it can't be
  # unlocked). swaylock-plugin calls pam_start("swaylock-plugin", ...), so the
  # PAM service must be named to match the binary — a plain "swaylock" service
  # is never consulted and PAM falls through to /etc/pam.d/other, which denies
  # every password (correct ones included). We define both names so either
  # binary works.
  security.pam.services.swaylock = { };
  security.pam.services.swaylock-plugin = {
    # Run the console-feedback hook on every auth attempt. `optional` means its
    # result is ignored (it can never affect whether the unlock succeeds), and
    # `expose_authtok` feeds the typed password to the script on stdin so it can
    # measure its length for the on-screen mask. Ordered after pam_fprintd
    # (order 11400, added automatically once fprintd is enabled — see
    # modules/system/fingerprint.nix) and just before pam_unix (default 11500),
    # so it fires on every password submit. A fingerprint unlock satisfies the
    # `sufficient` fprintd rule first and skips this hook entirely, which is fine
    # — there are no typed keystrokes to mask in that case.
    rules.auth.exec = {
      order = 11450;
      control = "optional";
      modulePath = "${pkgs.pam}/lib/security/pam_exec.so";
      args = [ "expose_authtok" "quiet" "${lockFeedbackHook}" ];
    };
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    wl-clipboard
    grim
    slurp
    brightnessctl
    pavucontrol
  ];
}

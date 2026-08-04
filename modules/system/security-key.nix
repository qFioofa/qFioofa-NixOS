# USB FIDO2/U2F security keys (YubiKey, Nitrokey, SoloKey, ...).
#
# Browser WebAuthn / passkeys on Linux need read+write access to the key's
# hidraw device. That is granted by the 70-u2f.rules udev rules shipped by
# libfido2 (GROUP="plugdev", TAG+="uaccess"), so the user must be in `plugdev`.
# 69-yubikey.rules from yubikey-personalization covers the ykpersonalize tool.
#
# `security.pam.u2f` additionally lets the same key replace the password for
# sudo/login. control = "sufficient" tries the key and falls back to password,
# so nothing breaks until a key is enrolled. Enroll one with:
#   pamu2fcfg -u "$(whoami)" > ~/.config/Yubico/u2f_keys
{ pkgs, ... }:
{
  services.udev.packages = [
    pkgs.libfido2
    pkgs.yubikey-personalization
  ];

  environment.systemPackages = with pkgs; [
    libfido2 # fido2-cred / fido2-assert: create & verify FIDO2 credentials
    yubikey-manager # ykman: manage YubiKey (FIDO2, OTP, PIV, OATH)
    yubikey-personalization # ykpersonalize / ykinfo
    pam_u2f # pamu2fcfg: generate the u2f_keys file
  ];

  security.pam.u2f = {
    enable = true;
    control = "sufficient";
  };
}

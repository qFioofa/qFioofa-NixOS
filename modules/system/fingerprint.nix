# Fingerprint reader (fprintd + libfprint) for PAM login/unlock.
#
# NOTE: The built-in Goodix 27c6:5125 sensor in the Huawei Matebook is NOT
# supported on Linux — no kernel module, libfprint driver or TOD driver claims
# it (fprintd reports "No driver found for USB device 27C6:5125"). All 765
# linux-hardware.org probes for this device are "failed". The experimental
# goodix-fp-linux-dev reverse-engineered driver is unstable and does not
# integrate with fprintd/FIDO2 anyway, so no config can enable it.
#
# fprintd stays enabled in case this config is reused on a host with a
# supported sensor; it is a harmless no-op on the Matebook.
{ ... }:
{
  services.fprintd.enable = true;
}

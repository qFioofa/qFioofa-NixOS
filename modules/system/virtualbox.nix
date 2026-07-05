{ ... }:
{
  # Builds/loads the vboxdrv kernel module and installs VirtualBox system-wide.
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "qFioofa" ];
}

{ ... }:
# Shared host bootstrap: every host imports this to pull in the OS modules and
# the root user. Machine-specific settings then layer on top (see
# hosts/<name>/default.nix).
{
  imports = [
    ../modules
    ./root/user.nix
  ];
}

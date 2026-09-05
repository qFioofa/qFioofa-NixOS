{ ... }:
# Level boundary markers. `modules/` holds OS-level (system-wide, root-owned)
# modules; per-user dotfiles live in `home/`, per-machine in `hosts/`.
{
  imports = [
    ./system
    ./desktop
  ];
}

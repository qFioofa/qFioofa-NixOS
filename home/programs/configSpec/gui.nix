{ ... }:
# GUI-only feature modules (browser, media viewers, graphics terminals). Not
# imported by the headless WSL profile.
{
  imports = [
    ./firefox.nix
    ./media.nix
    ./ghostty.nix
    ./wezterm.nix
  ];
}

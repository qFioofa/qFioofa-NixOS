{ ... }:
# Terminal-only feature modules. Safe to import on headless hosts (e.g. the
# WSL profile), unlike gui.nix which pulls in GUI apps.
{
  imports = [
    ./zsh.nix
    ./nvim.nix
    ./tmux.nix
    ./lazygit.nix
    ./clangd.nix
  ];
}

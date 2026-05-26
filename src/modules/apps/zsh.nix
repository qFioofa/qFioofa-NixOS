{ pkgs, ... }: {
  programs.zsh.enable = true;  # registers zsh in /etc/shells

  environment.systemPackages = [ pkgs.starship ];
}

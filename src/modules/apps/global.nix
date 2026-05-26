{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    curl wget jq
    bat eza fd ripgrep fzf zoxide
    btop tree
    unzip p7zip
    file which
  ];
}

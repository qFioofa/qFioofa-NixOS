{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    curl 
	wget 
	jq 
	tree 
	htop 
	bat 
	eza 
	fzf 
	ripgrep 
	zoxide
  ];
}

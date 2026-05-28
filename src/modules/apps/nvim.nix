{ pkgs, ... }: {
  environment.variables.EDITOR = "nvim";

  environment.systemPackages = with pkgs; [
    lua-language-server  nil  pyright
    stylua  nixfmt-rfc-style  prettierd
    gcc  gnumake  nodejs
  ];
}

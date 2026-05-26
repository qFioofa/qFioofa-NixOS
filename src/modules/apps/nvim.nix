{ pkgs, ... }: {
  environment.variables.EDITOR = "nvim";

  environment.systemPackages = with pkgs; [
    lua-language-server  nil  nodePackages.typescript-language-server  pyright
    stylua  nixfmt-rfc-style  prettierd
    gcc  gnumake  nodejs
  ];
}

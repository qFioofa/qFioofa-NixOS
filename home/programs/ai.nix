{ pkgs, ... }:

let
  omniroute = pkgs.writeShellScriptBin "omniroute" ''
    exec ${pkgs.nodejs}/bin/npx --yes omniroute "$@"
  '';
in
{
  home.packages = with pkgs; [
    claude-code
    omniroute
    opencode
  ];
}

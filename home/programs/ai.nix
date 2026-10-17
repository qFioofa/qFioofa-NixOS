{ pkgs, inputs, ... }:

let
  omniroute = pkgs.writeShellScriptBin "omniroute" ''
    exec ${pkgs.nodejs}/bin/npx --yes omniroute "$@"
  '';
in
{
  home.packages = with pkgs; [
    claude-code
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    omniroute
    opencode
  ];
}

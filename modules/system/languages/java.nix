{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    jdk21
    maven
    gradle
    jdt-language-server
  ];
}

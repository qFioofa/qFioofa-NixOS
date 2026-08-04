{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    jdk21
    maven
    gradle
    jdt-language-server
    spring-boot-cli
  ];

  environment.sessionVariables.JAVA_HOME = "${pkgs.jdk21.home}";
}

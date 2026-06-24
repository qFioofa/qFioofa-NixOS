{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    jdk21
    maven
    gradle
    jdt-language-server
  ];

  # JAVA_HOME so LSPs (jdt-language-server) and maven/gradle find the JDK.
  environment.sessionVariables.JAVA_HOME = "${pkgs.jdk21.home}";
}

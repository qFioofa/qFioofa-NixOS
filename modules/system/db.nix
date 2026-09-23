{ pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;

    enableTCPIP = false;

    ensureDatabases = [ "qFioofa" ];
    ensureUsers = [
      {
        name = "qFioofa";
        ensureDBOwnership = true;
      }
    ];

    authentication = pkgs.lib.mkOverride 10 ''
      # TYPE  DATABASE  USER  ADDRESS       METHOD
      local   all       all                 peer
      host    all       all   127.0.0.1/32  scram-sha-256
      host    all       all   ::1/128       scram-sha-256
    '';
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;

    ensureDatabases = [ "qFioofa" ];
    ensureUsers = [
      {
        name = "qFioofa";
        ensurePermissions = {
          "qFioofa.*" = "ALL PRIVILEGES";
        };
      }
    ];

    settings = {
      mysqld = {
        bind-address = "127.0.0.1";
        skip-networking = false;
      };
    };
  };
}

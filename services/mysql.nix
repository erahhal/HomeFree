{ pkgs, ... }:
{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    configFile = pkgs.writeText "mysql.cnf" ''
      [mysqld]
      datadir = /var/lib/mysql
      bind-address = 127.0.0.1
      bind-address = 10.0.0.1
      port = 3306
    '';
  };
}

{ pkgs, ... }:
{
services.radicale = {
  enable = true;
  settings = {
    server.hosts = [ "0.0.0.0:5232" ];
    # auth = {
    #   type = "htpasswd";
    #   htpasswd_filename = "/path/to/htpasswd/file/radicale_users";
    #   # hash function used for passwords. May be `plain` if you don't want to hash the passwords
    #   htpasswd_encryption = "bcrypt";
    # };
  };
};
}

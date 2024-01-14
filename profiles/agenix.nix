{ agenix, options, system, ... }:
{
  environment.systemPackages = [
    agenix.packages.${system}.default
  ];

  age.secrets.ddclient.file = ../secrets/ddclient.age;
  age.secrets.ddclient-conf.file = ../secrets/ddclient-conf.age;

  # default path is /etc/ssh/ssh_host_rsa_key
  age.identityPaths = options.age.identityPaths.default ++ [
    "/home/homefree/.ssh/id_rsa"
  ];
}

{ config, pkgs, lib, ... }:
let
  ## @TODO: replae this
  # config-path = "/etc/nixos";
  config-path = "/home/${config.homefree.system.adminUsername}/nixcfg";
  runtime-paths = lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.gawk
    pkgs.gnugrep
    pkgs.gnused
    pkgs.iproute2
    pkgs.nix-editor
    pkgs.procps
    pkgs.vulnix
  ];
  ## @TODO: read directly from nix-config
  admin-config = {
    wanInterface = config.homefree.network.wan-interface;
    lanInterface = config.homefree.network.lan-interface;
    services =
    let
      filtered = lib.filter (service-config: service-config.admin.show == true && service-config.reverse-proxy.enable == true) config.homefree.service-config;
      compareByName = a: b: a.name < b.name;
      sorted = builtins.sort compareByName filtered;
    in
    lib.map (service-config:
      let
        ## @TODO: Strip leading slash and add it explicitly
        path = if service-config.admin.urlPathOverride != null then service-config.admin.urlPathOverride else "";
        subdomain = builtins.head service-config.reverse-proxy.subdomains;
        domain = if (builtins.length service-config.reverse-proxy.https-domains > 0) then (builtins.head service-config.reverse-proxy.https-domains)
                 else if (builtins.length service-config.reverse-proxy.http-domains > 0) then (builtins.head service-config.reverse-proxy.http-domains)
                 ## @TODO: Add assertion in module.nix that ensures there is at least one domain
                 else "";
      in
      {
        service-config = service-config;
        ## Use first defined subomdain
        ## @TODO: supply a list of URLs instead
        url = ''https://${subdomain}.${domain}${path}'';
      }
    ) sorted;
  };
  config-json = (pkgs.formats.json {}).generate "admin-config.json" admin-config;

  preStart = ''
    mkdir -p /run/homefree/admin

    cp ${config-json} /run/homefree/admin/config.json
  '';
in
{
  ## @TODO: Defaults to port 4000. Create a parameter
  ##        that can be passed in to deno command line

  ## @TODO: Make a proper package so that Deno doesn't
  ##        pull down deps at runtime
  systemd.services.admin-api = {
    description = "Admin API Service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      User = "root";
      Group = "root";
      WorkingDirectory = "${./.}";
      ExecStartPre = [ "!${pkgs.writeShellScript "homefree-admin-prestart" preStart}" ];
      ExecStart = "${pkgs.deno}/bin/deno task start";
      Restart = "always";
      Environment="PATH=$PATH:${runtime-paths}";
    };
  };

  homefree.service-config = [
    {
      name = "HomeFree API";
      project-name = "HomeFree API";
      label = "admin-api";
      systemd-service-names = [
        "admin-api"
        "caddy"
      ];
      admin = {
        show = false;
      };
      reverse-proxy = {
        enable = true;
        subdomains = [ "api" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "localhost";
        ## @TODO: Defaults to port 4000. Create a parameter
        ##        that can be passed in to deno command line
        port = 4000;
        ## @TODO: Don't allow this to be public until locked down
        # public = config.homefree.admin-page.public;
        public = false;
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    deno
  ];
}

## @TODOs
## - Look into HACS integration:
##   - https://community.home-assistant.io/t/installing-hacs-is-tricky-in-docker-but-the-documentation-is-very-straightforward-when-you-know-how-to-read/450283
## - Look into using packaged custom components:
##   - https://github.com/NixOS/nixpkgs/tree/nixos-24.11/pkgs/servers/home-assistant/custom-components
{ config, pkgs, ... }:
let
  version = "2025.1";

  containerDataPath = "/var/lib/homeassistant";

  port = 8123;

  format = pkgs.formats.yaml {};

  # Post-process YAML output to add support for YAML functions, like
  # secrets or includes, by naively unquoting strings with leading bangs
  # and at least one space-separated parameter.
  # https://www.home-assistant.io/docs/configuration/secrets/
  renderYAMLFile = fn: yaml: pkgs.runCommandLocal fn { } ''
    cp ${format.generate fn yaml} $out
    sed -i -e "s/'\!\([a-z_]\+\) \(.*\)'/\!\1 \2/;s/^\!\!/\!/;" $out
  '';

  ha-config = {
    default_config = {};

    fontend = {
      themes = "!include_dir_merge_named themes";
    };

    automation = "!include automations.yaml";
    script = "!include scripts.yaml";
    scene = "!include scenes.yaml";
    group = "!include groups.yaml";

    http = {
      use_x_forwarded_for = true;
      trusted_proxies = "10.0.0.1";
    };

    auth_header = {
      debug = true;
    };

    logger = {
      default = "info";
      logs = {
        custom_components.auth_header = "debug";
      };
    };
  };

  config-yaml = renderYAMLFile "configuration.yaml" ha-config;

  preStart = ''
    mkdir -p ${containerDataPath}/config
    mkdir -p ${containerDataPath}/config/custom_components
    ln -sfn ${pkgs.home-assistant-custom-components.auth-header}/custom_components/auth_header ${containerDataPath}/config/custom_components/

    cp ${config-yaml} ${containerDataPath}/config/configuration.yaml
  '';
in
{
  virtualisation.oci-containers.containers = if config.homefree.services.homeassistant.enable == true then {
    homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:${version}";

      autoStart = true;

      extraOptions = [
        # "--pull=always"
        "--network=host"
        "--privileged"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${containerDataPath}/config:/config"
        "/run/dbus:/run/dbus:ro"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
      };
    };
  } else {};

  systemd.services.podman-homeassistant = {
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    partOf =  [ "nftables.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "homeassistant-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.homeassistant.enable == true then [
    {
      label = "homeassistant";
      name = "Home Assistant";
      project-name = "Home Assistant";
      systemd-service-names = [
        "podman-homeassistant"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "homeassistant" "ha" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.homeassistant.public;
      };
      backup = {
        paths = [
          containerDataPath
        ];
      };
    }
  ] else [];
}

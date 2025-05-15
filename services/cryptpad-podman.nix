{ config, lib, pkgs, ... }:
let
  version = "version-2025.3.0";
  containerDataPath = "/var/lib/cryptpad-podman";

  port = 3004;
  wsPort = 3023;
  dockerUserId = 4001;
  dockerGroupId = 4001;

  CPAD_MAIN_DOMAIN = "https://docs.${config.homefree.system.domain}";
  CPAD_SANDBOX_DOMAIN = "https://docs-sandbox.${config.homefree.system.domain}";

  ## @TODO: Add SSO
  ## https://github.com/cryptpad/cryptpad/blob/main/config/sso.example.js

  ## @TODO: Fix all issues here:
  ## https://docs.homefree.host/checkup/

  cryptpadConfig = pkgs.writeText "cryptpad-config.js" ''
    module.exports = {
      httpUnsafeOrigin: '${CPAD_MAIN_DOMAIN}',
      httpSafeOrigin: "${CPAD_SANDBOX_DOMAIN}",
      httpAddress: '0.0.0.0',
      httpPort: ${toString port},
      /* Local development instance port */
      //httpSafePort: 3001,
      websocketPort: ${toString wsPort},
      /* Default: 4 */
      maxWorkers: 8,
      otpSessionExpiration: 7*24, // hours
      //enforceMFA: false,
      //logIP: false,
      adminKeys: [
        ${lib.concatStringsSep "," (lib.map (key: ''"${key}"'') config.homefree.services.cryptpad.adminKeys)}
      ],
      //inactiveTime: 90, // days
      //archiveRetentionTime: 15,
      //accountRetentionTime: 365,
      //disableIntegratedEviction: true,
      maxUploadSize: 200 * 1024 * 1024,
      //premiumUploadSize: 100 * 1024 * 1024,
      filePath: './datastore/',
      archivePath: './data/archive',
      pinPath: './data/pins',
      taskPath: './data/tasks',
      blockPath: './block',
      blobPath: './blob',
      blobStagingPath: './data/blobstage',
      decreePath: './data/decrees',
      logPath: './data/logs',
      logToStdout: true,
      logLevel: 'info',
      logFeedback: false,
      verbose: false,
      installMethod: 'unspecified',
    };
  '';

  preStart = ''
    mkdir -p ${containerDataPath}/config
    mkdir -p ${containerDataPath}/data/blob
    mkdir -p ${containerDataPath}/data/block
    mkdir -p ${containerDataPath}/data/data
    mkdir -p ${containerDataPath}/data/files
    mkdir -p ${containerDataPath}/customize
    mkdir -p ${containerDataPath}/onlyoffice-dist
    mkdir -p ${containerDataPath}/onlyoffice-conf

    cp ${cryptpadConfig} ${containerDataPath}/config/config.js

    chown -R ${toString dockerUserId}:${toString dockerGroupId} ${containerDataPath}
  '';
in
{
  virtualisation.oci-containers.containers = if config.homefree.services.cryptpad.enable == true then {
    cryptpad = {
      image = "cryptpad/cryptpad:${version}";

      autoStart = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:${toString port}"
        "0.0.0.0:${toString wsPort}:${toString wsPort}"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${containerDataPath}/config/config.js:/cryptpad/config/config.js:ro"
        "${containerDataPath}/data/blob:/cryptpad/blob"
        "${containerDataPath}/data/block:/cryptpad/block"
        "${containerDataPath}/data/data:/cryptpad/data"
        "${containerDataPath}/data/files:/cryptpad/datastore"
        "${containerDataPath}/customize:/cryptpad/customize"
        "${containerDataPath}/onlyoffice-dist:/cryptpad/www/common/onlyoffice/dist"
        "${containerDataPath}/onlyoffice-conf:/cryptpad/onlyoffice-conf"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
        ## @TODO: move away from root user
        PUID = "1000";
        PGID = "100";
        CPAD_MAIN_DOMAIN = CPAD_MAIN_DOMAIN;
        CPAD_SANDBOX_DOMAIN = CPAD_SANDBOX_DOMAIN;
        CPAD_INSTALL_ONLYOFFICE = "yes";
        CPAD_CONF = "/cryptpad/config/config.js";
      };
    };
  } else {};

  systemd.services.podman-cryptpad = {
    after = [ "dns-ready.service" ];
    requires =[ "dns-ready.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "cryptpad-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.cryptpad.enable == true then [
    {
      label = "cryptpad";
      name = "Docs/Office Suite";
      project-name = "Cryptpad";
      systemd-service-names = [
        "podman-cryptpad"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "docs" "docs-sandbox" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.cryptpad.public;
      };
      backup = {
        paths = [
          containerDataPath
        ];
      };
    }
  ] else [];
}

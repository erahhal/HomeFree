{ config, pkgs, ... }:
let
  containerDataPath = "/var/lib/ollama-webui";

  preStart = ''
    mkdir -p ${containerDataPath}
  '';

  port-internal = 8254;
  port = 3014;
in
{
  environment.systemPackages = [
    pkgs.ollama
  ];

  services.ollama = {
    enable = true;
    ## Default: 11434
    port = 11434;
    host = "[::]";
    loadModels = [
      "deepseek-r1"
    ];
  };

  virtualisation.oci-containers.containers = if config.homefree.services.baikal.enable == true then {
    ollama-webui = {
      image = "ghcr.io/open-webui/open-webui:main";

      autoStart = true;

      extraOptions = [
        "--pull=always"
        "--add-host=host.docker.internal:host-gateway"
      ];

      ports = [
        "0.0.0.0:${toString port}:${toString port-internal}"
      ];

      volumes = [
        "${containerDataPath}:/app/backend/data"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
        PORT = toString port-internal;
        WEBUI_URL = "https://ollama.${config.homefree.system.domain}";
        OLLAMA_BASE_URL = "http://10.0.0.1:${toString config.services.ollama.port}";
        ## @TODOS
        # WEBUI_SECRET_KEY
        # DEFAULT_LOCALE
        # DEFAULT_PROMPT_SUGGESTIONS
        # CORS_ALLOW_ORIGIN (defualt is *)
        # USER_AGENT
        ## Single user mode (can't change after first run)
        # WEBUI_AUTH=False
      };
    };
  } else {};

  systemd.services.podman-ollama-webui = {
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "ollama-webui-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.ollama.enable == true then [
    {
      label = "ollama";
      name = "Ollama";
      project-name = "Ollama";
      ## @TODO: Why is this not a list?
      systemd-service-names = [
        "ollama"
        "podman-ollama-webui"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "ollama" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.ollama.public;
      };
      backup = {
        paths = [
          containerDataPath
        ];
      };
    }
  ] else [];
}

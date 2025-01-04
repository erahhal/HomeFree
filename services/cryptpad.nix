{ config, ... }:
{
  services.cryptpad = {
    enable = config.homefree.services.cryptpad.enable;
    configureNginx = false;
    settings = {
      httpPort = 3004;
      httpAddress = "10.0.0.1";
      blockDailyCheck = true;
      httpUnsafeOrigin = "https://docs.${config.homefree.system.domain}";
      httpSafeOrigin = "https://docs-ui.${config.homefree.system.domain}";

      # Add this after you've signed up in your Cryptpad instance and copy your public key:
      # adminKeys = [ "[user@cryptpad.example.com/Jil1apEPZ40j5M8nsjO1-deadbeefHkt+QExscMzKhs=]" ];
    };
  };

  homefree.service-config = if config.homefree.services.cryptpad.enable == true then [
    {
      label = "cryptpad";
      name = "Docs/Office Suite";
      project-name = "Cryptpad";
      systemd-service-name = "cryptpad";
      reverse-proxy = {
        enable = true;
        # subdomains = [ "cryptpad" "cryptpad-sandbox" "cryptpad-ui" ];
        subdomains = [ "docs" "docs-sandbox" "docs-ui" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 3004;
        public = config.homefree.services.cryptpad.public;
      };
      backup = {
        paths = [
          "/var/lib/private/cryptpad"
        ];
      };
    }
  ] else [];
}

{ config, ... }:
{
  services.cryptpad = {
    enable = config.homefree.services.cryptpad.enable;
    configureNginx = false;
    settings = {
      httpPort = 3004;
      httpAddress = "10.0.0.1";
      blockDailyCheck = true;
      httpUnsafeOrigin = "https://cryptpad.${config.homefree.system.domain}";
      httpSafeOrigin = "https://cryptpad-ui.${config.homefree.system.domain}";

      # Add this after you've signed up in your Cryptpad instance and copy your public key:
      # adminKeys = [ "[user@cryptpad.example.com/Jil1apEPZ40j5M8nsjO1-deadbeefHkt+QExscMzKhs=]" ];
    };
  };

  homefree.proxied-hosts = if config.homefree.services.cryptpad.enable == true then [
    {
      label = "cryptpad";
      subdomains = [ "cryptpad" "cryptpad-sandbox" "cryptpad-ui" ];
      http-domains = [ "homefree.${config.homefree.system.localDomain}" ];
      https-domains = [ config.homefree.system.domain ];
      port = 3004;
      public = config.homefree.services.cryptpad.public;
    }
  ] else [];
}

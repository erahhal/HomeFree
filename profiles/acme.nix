{ config, ... }:
{
  ## Required by Cryptpad and potentially other services
  security.acme = {
    defaults = {
      ## @TODO: Replace with a real email from config
      email = "${config.homefree.system.adminUsername}@${config.homefree.system.domain}";
    };
    acceptTerms = true;
  };
}

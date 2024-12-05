{ ... }:
{
  ## @TODO: Add password auth
  ## https://nixos.wiki/wiki/Mosquitto
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };
}

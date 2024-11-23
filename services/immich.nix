{ ... }:
{
  services.immich = {
    enable = true;
    environment.IMMICH_MACHINE_LEARNING_URL = "http://localhost:3003";
  };

  ## Enable VA-API support
  users.users.immich.extraGroups = [ "video" "render" ];
}

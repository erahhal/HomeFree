{ ... }:
{
  # YAML is the default
  #sops.defaultSopsFormat = "yaml";
  sops.secrets."authentik/authentik-env" = {
    format = "yaml";
    # can be also set per secret
    sopsFile = ./authentik.yaml;
  };
}

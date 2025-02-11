{ config, pkgs, ... }:
{
  services.jellyfin = {
    enable = config.homefree.services.jellyfin.enable;
    openFirewall = true;
    user = config.homefree.system.adminUsername;
  };

  environment.systemPackages = [
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
  ];

  ## Support Intro Skipper plugin
  nixpkgs.overlays = with pkgs; [
    (
      final: prev:
        {
          jellyfin-web = prev.jellyfin-web.overrideAttrs (finalAttrs: previousAttrs: {
            installPhase = ''
              runHook preInstall

              # this is the important line
              sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script></head>#" dist/index.html

              mkdir -p $out/share
              cp -a dist $out/share/jellyfin-web

              runHook postInstall
            '';
          });
        }
    )
  ];

  ##--------------------------------------------------------------------------------
  ## Enable hardware transcoding
  ## Only works on Intel
  ## @TODO: Move to hardware config
  ## @TODO: Add flags for which capabilities are needed by each service
  ##--------------------------------------------------------------------------------

  ## enable vaapi on OS-level
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver # previously vaapiIntel
      vaapiVdpau
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      vpl-gpu-rt # QSV on 11th gen or newer
      intel-media-sdk # QSV up to 11th gen
    ];
  };

  homefree.service-config = if config.homefree.services.jellyfin.enable == true then [
    {
      label = "jellyfin";
      name = "Streaming Video";
      project-name = "Jellyfin";
      systemd-service-names = [
        "jellyfin"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "media" "video" "jellyfin" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 8096;
        public = config.homefree.services.jellyfin.public;
      };
    }
  ] else [];
}

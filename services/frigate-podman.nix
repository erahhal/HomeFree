{ config, lib, pkgs, ... }:
let
  version = "0.15.0";
  configVersion = "0.15-1";
  containerDataPath = "/var/lib/frigate";
  mediaPath = config.homefree.services.frigate.media-path or "${containerDataPath}/media";
  cameras-filtered = lib.filter (camera: camera.enable == true) config.homefree.services.frigate.cameras;

  frigate-config = {
    version = configVersion;

    detectors = {
      coral = {
        type = "edgetpu";
        device = "usb";
        # num_threads = 3;
      };
    };

    ffmpeg = {
      ## Intel
      hwaccel_args = "preset-intel-qsv-h264";

      ## Raspberry Pi
      # hwaccel_args = "-c:v h264_v4l2m2m";
    };

    mqtt = {
      host = "10.0.0.1";
      port = 1883;
      topic_prefix = "frigate";
      ## Must be unique if running multiple instances
      client_id = "frigate";
      stats_interval = 60;
    };

    objects = {
      track = [
        "person"
        "bicycle"
        "dog"
        "cat"
      ];
    };

    record = {
      enabled = true;
      # ## Minutes
      # expire_interval = 60;
      retain = {
        days = 3;
        mode = "all";
      };
      alerts = {
        retain = {
          days = 30;
          mode = "motion";
        };
      };
      detections = {
        retain = {
          days = 30;
          mode = "motion";
        };
      };
    };

    snapshots = {
      # Optional: Enable writing jpg snapshot to /media/frigate/clips (default: shown below)
      # This value can be set via MQTT and will be updated in startup based on retained value
      enabled = true;
      # Optional: print a timestamp on the snapshots (default: shown below)
      timestamp = false;
      # Optional: draw bounding box on the snapshots (default: shown below)
      bounding_box = false;
      # Optional: crop the snapshot (default: shown below)
      crop = false;
      # # Optional: height to resize the snapshot to (default: original size)
      # height = 175;
      # Optional: Camera override for retention settings (default: global values)
      retain = {
        # Required: Default retention days (default: shown below)
        default = 10;
        # Optional: Per object retention days
        objects = {
          person = 15;
        };
      };
    };

    birdseye = {
      enabled = true;
      mode = "continuous";
    };

    cameras = lib.listToAttrs (lib.map (camera: {
      name = camera.name;
      value = {
        enabled = camera.enable;
        ffmpeg = {
          inputs = [
            {
              path = camera.path;
              roles = [
                "audio"
                "detect"
                "record"
              ];
            }
          ];
        };
        detect = {
          width = camera.width;
          height = camera.height;
          fps = 5;
        };
      };
    }) cameras-filtered);
  };

  config-yaml = (pkgs.formats.yaml {}).generate "frigate-config.yaml" frigate-config;

  preStart = ''
    mkdir -p ${containerDataPath}/config
    mkdir -p ${mediaPath}

    cp ${config-yaml} ${containerDataPath}/config/config.yaml
  '';
in
  {
    environment.systemPackages= [
    ## Google Coral (Edge TPU) USB Support
    pkgs.libedgetpu
  ];

  virtualisation.oci-containers.containers = if config.homefree.services.frigate.enable == true then {
    frigate = {
      image = "ghcr.io/blakeblackshear/frigate:${version}";

      autoStart  = true;

      extraOptions = [
        "--pull=always"
        ## 1GB of memory, reduces SSD/SD Card wear
        "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
        "--shm-size=512M"
        # "--network=bridge"
        "--device=/dev/bus/usb:/dev/bus/usb"  # Passes the USB Coral, needs to be modified for other versions
        "--device=/dev/dri/card1:/dev/dri/card1" # For intel hwaccel, needs to be updated for your hardware
        "--device=/dev/dri/renderD128:/dev/dri/renderD128" # For intel hwaccel, needs to be updated for your hardware
        "--cap-add=CAP_PERFMON" # For GPU statistics
        "--privileged"
      ];

      ports = [
        "0.0.0.0:8971:8971"
        "8554:8554" # RTSP feeds
        "8555:8555/tcp" # WebRTC over tcp
        "8555:8555/udp" # WebRTC over udp
      ];

      volumes = [
        "${containerDataPath}/config:/config"
        ## @TODO: make this configurable
        "${mediaPath}:/media/frigate"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
      };
    };
  } else {};

  systemd.services.podman-frigate = {
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "frigate-prestart" preStart}" ];
    };
  };

  # systemd.services.podman-create-frigate-network = {
  #   serviceConfig.Type = "oneshot";
  #   wantedBy = [ "podman-frigate.service" ];
  #   script = ''
  #     podman network create -d ipvlan --subnet 10.0.0.0/24 --ip-range 10.0.99.0/24 --ipam-driver host-local podnet
  #   '';
  # };

  homefree.service-config = if config.homefree.services.frigate.enable == true then [
    {
      label = "frigate";
      name = "NVR (Network Video Recorer)";
      project-name = "Frigate";
      systemd-service-names = [
        "podman-frigate"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "nvr" "frigate" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 8971;
        ssl = true;
        ssl-no-verify = true;
        public = config.homefree.services.frigate.public;
      };
      backup = if config.homefree.services.frigate.enable-backup-media then {
        paths = [
          mediaPath
        ];
      } else {};
    }
  ] else [];
}


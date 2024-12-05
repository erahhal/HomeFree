{ config, lib, pkgs, ... }:
let
  containerDataPath = "/var/lib/frigate";
  # mediaPath = "${containerDataPath}/media";
  mediaPath = "/mnt/ellis/nvr";

  cameras-filtered = lib.filter (camera: camera.enable == true) config.homefree.services.frigate.cameras;

  frigate-config = {
    version = 0.14;

    detectors = {
      coral = {
        type = "edgetpu";
        device = "usb";
        # num_threads = 3;
      };
    };

    ffmpeg = {
      ## Intel
      hwaccel_args = "preset-vaapi";

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
      ## Minutes
      expire_interval = 60;
      retain = {
        days = 2;
        mode = "all";
      };
      events = {
        # Optional: Number of seconds before the event to include (default: shown below)
        pre_capture = 5;
        # Optional: Number of seconds after the event to include (default: shown below)
        post_capture = 5;
        # Optional: Objects to save recordings for. (default: all tracked objects)
        objects = [
          "person"
          "bicycle"
          "dog"
          "cat"
        ];
        # Optional: Retention settings for recordings of events
        retain = {
          # Required: Default retention days (default: shown below)
          default = 10;
          # Optional: Mode for retention. (default: shown below)
          #   all - save all recording segments for events regardless of activity
          #   motion - save all recordings segments for events with any detected motion
          #   active_objects - save all recording segments for event with active/moving objects
          #
          # NOTE: If the retain mode for the camera is more restrictive than the mode configured
          #       here, the segments will already be gone by the time this mode is applied.
          #       For example, if the camera retain mode is "motion", the segments without motion are
          #       never stored, so setting the mode to "all" here won't bring them back.
          mode = "motion";
          # Optional: Per object retention days
          objects = {
            person = 30;
          };
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
        ffmpeg = {
          inputs = [
            {
              path = camera.path;
              roles = [
                "detect"
              ];
            }
          ];
        };
        detect = {
          width = camera.width;
          height = camera.height;
          fps = 5;
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
      image = "ghcr.io/blakeblackshear/frigate:stable";

      autoStart  = true;

      extraOptions = [
        "--pull=always"
        ## 1GB of memory, reduces SSD/SD Card wear
        "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
        # "--network=bridge"
        "--device=/dev/bus/usb:/dev/bus/usb"  # Passes the USB Coral, needs to be modified for other versions
        "--device=/dev/dri/renderD128:/dev/dri/renderD128" # For intel hwaccel, needs to be updated for your hardware
        "--cap-add=CAP_PERFMON" # For GPU statistics
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
      reverse-proxy = {
        enable = true;
        subdomains = [ "frigate" ];
        http-domains = [ "homefree.${config.homefree.system.localDomain}" ];
        https-domains = [ config.homefree.system.domain ];
        port = 8971;
        ssl = true;
        ssl-no-verify = true;
        public = config.homefree.services.frigate.public;
      };
    }
  ] else [];
}


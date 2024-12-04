{ config, ... }:
{
  services.frigate = {
    enable = config.homefree.services.frigate.enable;
    hostname = "localhost";

    settings = {
      mqtt.enabled = false;

      #detectors.ov = {
      #  type = "openvino";
      #  device = "AUTO";
      #  model.path = "/var/lib/frigate/openvino-model/ssdlite_mobilenet_v2.xml";
      #};

      record = {
        enabled = true;
        retain = {
          days = 2;
          mode = "all";
        };
      };

      ffmpeg.hwaccel_args = "preset-vaapi";

      cameras."gate" = {
        ffmpeg.inputs = [{
          path = "rtsp://admin:h3llb3nt@10.0.0.15/11";
          input_args = "preset-rtsp-restream";
          roles = [
            "record"
            "detect"
          ];
        }];
      };
      cameras."reolink-fixed" = {
        ffmpeg.inputs = [{
          path = "rtsp://6nAPdQpfVNmS:07kN6uekoI6e@10.0.0.17:554/live0";
          roles = [
            "record"
            "detect"
          ];
        }];
      };
      cameras."reolink-ptz" = {
        ffmpeg.inputs = [{
          path = "rtsp://p1mmL82zytvc:6C7qwtpTqFTE@10.0.0.18:554/live0";
          roles = [
            "record"
            "detect"
          ];
        }];
      };
    };
  };

  systemd.services.frigate = {
    # For libva-intel-driver use i965.
    # For intel-media-driver use iHD.
    environment.LIBVA_DRIVER_NAME = "i965";
    serviceConfig = {
      SupplementaryGroups = ["render" "video"] ; # for access to dev/dri/*
      AmbientCapabilities = "CAP_PERFMON";
    };
  };

  ## Converts to any format
  ## https://github.com/AlexxIT/go2rtc
  services.go2rtc = {
    enable = false;
    settings = {
      streams = {
        "test1" = [
          "rtsp://10.83.16.12/11"
        ];
      };
      rtsp.listen = ":8554";
      webrtc.listen = ":8555";
    };
  };
}

{ config, pkgs, ... }:

let
  # automations = import ./automations.nix;
  scenes = import ./scenes.nix;
  scripts = import ./scripts.nix;
  groups = import ./groups.nix;
in
{
  #-----------------------------------------------------------------------------------------------------
  # Home Assistant
  #-----------------------------------------------------------------------------------------------------

  imports = [
    # On first run, this has to be commented out, and a single user created.
    # Afterward, it can be re-included
    ## @TODO: Auto-initializatin for HA
    ## See: https://github.com/home-assistant/core/issues/16554
    ./ldap.nix
    ./trusted-networks.nix
    ./weather.nix
  ];

  services.home-assistant = {
    enable = config.homefree.services.homeassistant.enable;

    # Enable Postgres
    package = (pkgs.home-assistant.override {
      extraPackages = py: with py; [ psycopg2 ];
    }).overrideAttrs (oldAttrs: {
      doInstallCheck = false;
    });
    config.recorder.db_url = "postgresql://@/hass";

    extraComponents = [
      # Components required to complete the onboarding
      "adguard"
      "backup"
      "brother"
      "ecobee"
      "enphase_envoy"
      "esphome"
      "flume"
      "iaqualink"
      "jellyfin"
      "litterrobot"
      "met"
      "mqtt"
      "radio_browser"
      "roborock"
      "schlage"
      "snapcast"
      "synology_dsm"
      "unifi"
      "usgs_earthquakes_feed"
      "volumio"
      "wake_on_lan"
      "yamaha_musiccast"
      "zwave_js"
    ];

    customComponents = with pkgs.home-assistant-custom-components; [
      frigate
      smartthinq-sensors
    ];

    customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
      button-card
      card-mod
      decluttering-card
      lg-webos-remote-control
      light-entity-card
      mini-graph-card
      mini-media-player
      multiple-entity-row
      mushroom
      valetudo-map-card
    ];

    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};

      # "automation manual" = automations;
      "automation ui" = "!include automations.yaml";

      "scene manual" = scenes;
      "scene ui" = "!include scenes.yaml";

      "script manual" = scripts;
      "script ui" = "!include scripts.yaml";

      "group manual" = groups;
      # "group ui" = "!include groups.yaml";

      http = {
        # @TODO: Make this a passed-in var
        base_url = "ha.homefree.lan";
        use_x_forwarded_for = true;
        trusted_proxies = [
          # @TODO: Make this a passed-in var
          "127.0.0.1"
          "10.0.0.1"
          "10.0.2.15"
        ];
      };

      ## enable with empty top level key
      wake_on_lan = {};

      switch = [
        {
          platform = "wake_on_lan";
          mac = "B4-B2-91-52-DE-DF";
          name = "LGwebOSTV";
          host = "10.0.0.40";
        }
        {
          platform = "template";
          switches = {
            lg_tv = {
              unique_id = "lg-tv";
              friendly_name = "LG CX 65\" TV";
              value_template = "{{ is_state('media_player.lg_webos_smart_tv', 'on') }}";
              turn_on = {
                service = "switch.turn_on";
                target = {
                  entity_id = "switch.lgwebostv";
                };
              };
              turn_off = {
                service = "media_player.turn_off";
                target = {
                  entity_id = "media_player.lg_webos_smart_tv";
                };
              };
            };
          };
        }
      ];

      command_line = [
        {
          switch = {
            name = "msi_desktop";
            unique_id = "msi-desktop";
            command_state = "ping -c 2 -i 1 msi-desktop.${config.homefree.system.localDomain}";
            ## Hibernate
            # command_off = "ssh -i /run/agenix/msi-desktop-id_rsa -o 'StrictHostKeyChecking=no' erahhal@msi-desktop rundll32.exe powrprof.dll, SetSuspendState Sleep";
            command_on = "wakeonlan 2c:f0:5d:72:ac:ab";
            ## Suspend
            command_off = "ssh -i /config/certs/msi_desktop-id_rsa -o ConnectTimeout=30 -o 'StrictHostKeyChecking=no' erahhal@msi-desktop.${config.homefree.system.localDomain} 'cd \"/mnt/c/Program Files/PSTools\"; ./psshutdown.exe -accepteula -d -t 0'";
          };
        }
        {
          switch = {
            name = "stream_vr";
            unique_id = "steam-vr";
            command_on = "ssh -i /config/certs/msi_desktop-id_rsa -o ConnectTimeout=30 -o 'StrictHostKeyChecking=no' erahhal@msi-desktop.${config.homefree.system.localDomain} 'cd \"/mnt/c/Program Files (x86)/Steam/steamapps/common/SteamVR/bin/win64\"; ./vrstartup.exe'";
          };
        }
      ];

      # media_player = [
      #   {
      #     platform = "yamaha";
      #     host = "10.0.0.41";
      #     source_names = {
      #       HDMI1 = "PC HDMI";
      #     };
      #     zone_names = {
      #       Main_Zone = "Family Room";
      #     };
      #   }
      # ];

      sensor = [
        # See: https://github.com/home-assistant/core/issues/64839
        {
          platform = "template";
          sensors = {
            # ZWaveJS Node Stats
            zwavejs_node_statistics = {
              friendly_name = "ZwaveJS Node Statistics";
              icon_template = ''
                {%- if states | selectattr('entity_id', 'search', '_node_status') | selectattr('state', 'in', 'dead, unknown') | list | count > 0 -%}
                  mdi:emoticon-sad
                {%- elif states | selectattr('entity_id', 'search', '_node_status') | rejectattr('state', 'in', 'alive, asleep, dead, unknown') | list | count > 0 -%}
                  mdi:help-circle
                {%- else -%}
                  mdi:z-wave
                {%- endif -%}
              '';
              value_template = "{{ states | selectattr('entity_id', 'search', '_node_status') | list | count }}";
              attribute_templates = {
                Alive = "{{ states | selectattr('entity_id', 'search', '_node_status') | selectattr('state', 'in', 'alive') | list | count }}";
                Sleeping = "{{ states | selectattr('entity_id', 'search', '_node_status') | selectattr('state', 'in', 'asleep') | list | count }}";
                Dead = "{{ states | selectattr('entity_id', 'search', '_node_status') | selectattr('state', 'in', 'dead, unknown') | list | count }}";
              };
            };
          };
        }
        # {
        #   platform = "hp_ilo";
        #   host = "10.0.0.9";
        #   username = "Administrator";
        #   # @TODO: REMOVE
        #   password = "CHANGEME";
        #   monitored_variables = [
        #     {
        #       name = "CPU fanspeed";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "%";
        #       value_template = "{{ ilo_data.fans[\"Fan 1\"].speed[0] }}";
        #     }
        #     {
        #       name = "Fan 2";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "%";
        #       value_template = "{{ ilo_data.fans[\"Fan 2\"].speed[0] }}";
        #     }
        #     {
        #       name = "Fan 3";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "%";
        #       value_template = "{{ ilo_data.fans[\"Fan 3\"].speed[0] }}";
        #     }
        #     {
        #       name = "Server Health";
        #       sensor_type = "server_health";
        #       value_template = "{{ ilo_data.health_at_a_glance }}";
        #     }
        #     {
        #       name = "Server Power Readings (raw)";
        #       sensor_type = "server_power_readings";
        #     }
        #     {
        #       name = "Server Power Status (raw)";
        #       sensor_type = "server_power_status";
        #     }
        #     {
        #       name = "Server health (raw)";
        #       sensor_type = "server_health";
        #     }
        #     {
        #       name = "Inlet temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"01-Inlet Ambient\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "Inlet temperature (raw)";
        #       sensor_type = "server_health";
        #       value_template = "{{ ilo_data.temperature[\"01-Inlet Ambient\"] }}";
        #     }
        #     {
        #       name = "CPU 1 temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"02-CPU 1\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "P1 DIMM 1-4 temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"03-P1 DIMM 1-4\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "HD Max temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"04-HD Max\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "Chipset temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"05-Chipset\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "VR P1 temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"07-VR P1\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "SuperCAP Max temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"08-Supercap Max\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "iLO Zone temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"09-iLO Zone\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "LOM Zon temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"11-LOM Zone\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "PCI 2 temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"13-PCI 2\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "PCI 1 Zone temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"14-PCI 1 Zone\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "PCI 2 Zone temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"15-PCI 2 Zone\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "System Board temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"16-System Board\"].currentreading[0] }}";
        #     }
        #     {
        #       name = "Sys Exhaust temperature";
        #       sensor_type = "server_health";
        #       unit_of_measurement = "°C";
        #       value_template = "{{ ilo_data.temperature[\"17-Sys Exhaust\"].currentreading[0] }}";
        #     }
        #   ];
        # }
        # {
        #   # This includes the config necessary for a washer and dryer.
        #   # Code for dishwasher and mini-washer may be commented out as-needed,
        #   # and are presented only for reference purposes.
        #
        #   # NOTE: YOUR ENTITY NAMES MAY BE DIFFERENT, THEN THIS WON'T WORK WITHOUT TWEAKING
        #   # =================================================================================
        #   # If your washer doesn't have entities named sensor.washer, sensor.washer_run_state
        #   # (and similar for dryer), you have to change the names throughout here!
        #
        #   # NOTE: THIS CODE EXPECTS YOUR THINQ INTEGRATION TO RETURN ENGLISH STRINGS
        #   # =================================================================================
        #   # if your LG account is in another region/language, this will probably break unless
        #   # you take the time to change out state strings like "Standby". Do this by watching
        #   # your machine's entities change states during a run, or look at its history.
        #
        #   platform = "template";
        #   sensors = {
        #     front_load_washer_door_lock = {
        #        friendly_name = "Washer Door Lock";
        #        value_template = "{{ state_attr('sensor.front_load_washer','door_lock') }}";
        #     };
        #     front_load_washer_time_display = {
        #       friendly_name = "Washer Time Display";
        #       value_template = ''
        #         {% if is_state('sensor.front_load_washer_run_state', '-') %}
        #         {% elif is_state('sensor.front_load_washer_run_state', 'unavailable') %}
        #         {% elif is_state('sensor.front_load_washer_run_state', 'Standby') %}
        #           -:--
        #         {% else %}
        #           {{ state_attr("sensor.front_load_washer","remain_time").split(":")[:-1] | join(':') }}
        #         {% endif %}
        #       '';
        #     };
        #
        #     dryer_time_display = {
        #       friendly_name = "Dryer Time Display";
        #       value_template = ''
        #         {% if is_state('sensor.dryer_run_state', '-') %}
        #         {% elif is_state('sensor.dryer_run_state', 'unavailable') %}
        #         {% elif is_state('sensor.dryer_run_state', 'Standby') %}
        #           -:--
        #         {% else %}
        #           {{ state_attr("sensor.dryer","remain_time").split(":")[:-1] | join(':') }}
        #         {% endif %}
        #       '';
        #     };
        #
        #     blank = {
        #       friendly_name = "Blank Sensor";
        #       value_template = "";
        #     };
        #   };
        # }
      ];
    };
  };

  # Make sure UI-based config files exist in case they haven't been created yet
  systemd.tmpfiles.rules = [
    "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass"
    "f ${config.services.home-assistant.configDir}/scenes.yaml 0755 hass hass"
    "f ${config.services.home-assistant.configDir}/scripts.yaml 0755 hass hass"
  ];

  # HTTP port
  networking.firewall.allowedTCPPorts = [ 8123 ];

  # Database
  services.postgresql = {
    ensureDatabases = [ "hass" ];
    ensureUsers = [{
      name = "hass";
      ensureDBOwnership = true;
    }];
  };

  homefree.service-config = if config.homefree.services.homeassistant.enable == true then [
    {
      label = "homeassistant";
      reverse-proxy = {
        enable = true;
        subdomains = [ "homeassistant" "ha" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        port = 8123;
        public = config.homefree.services.homeassistant.public;
      };
      backup = {
        postgres-databases = [
          "hass"
        ];
      };
    }
  ] else [];
}

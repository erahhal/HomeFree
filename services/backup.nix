{ config, lib, pkgs, ... }:
let
  backup-to-path = config.homefree.backups.to-path;
  ## Combine service backup paths to extra custom paths into an array of { label = "label"; paths = []; }
  backup-from-paths-all =
    (lib.map (entry: {
      label = entry.label;
      paths = entry.backup.paths
        ## Add postgres database backup paths
        ++ (if (lib.length entry.backup.postgres-databases) > 0 then [ "/var/backup/postgresql-homefree/${entry.label}" ] else []);
    }) config.homefree.service-config)
    ++ [{ label = "extra-paths"; paths = config.homefree.backups.extra-from-paths; }];
  ## filter out any entries without backup paths
  filtered-backup-from-paths = lib.filter (entry: (lib.length entry.paths) > 0) backup-from-paths-all;
  ## Only populate paths if backups enabled
  backup-from-paths = if config.homefree.backups.enable == true then filtered-backup-from-paths else [];
  postgres-databases = lib.flatten (lib.map (entry: entry.backup.postgres-databases) config.homefree.service-config);
  service-to-postgres-databases-map  = lib.listToAttrs (lib.map (entry: {
    name = entry.label;
    value = entry.backup.postgres-databases;
  }) config.homefree.service-config);
in
{
  ## Typical rsync command
  ## rsync -avzP --delete --no-links src dest

  ## To see files in backup
  ## sudo restic ls latest -r local:<backup path>

  environment.systemPackages = [ pkgs.restic ];

  # --------------------------------------------------------------------------------------
  # Postgres Dumps
  # --------------------------------------------------------------------------------------

  services.postgresqlBackup = {
    enable = config.homefree.backups.enable;
    ## Default location. Just repeated here for reference and stability.
    location = "/var/backup/postgresql";
    databases = postgres-databases;
    ## This isn't really used, as backups are kicked off by restic below,
    ## so select the least frequent period.
    startAt = "yearly";
  };

  # --------------------------------------------------------------------------------------
  # Raw Snapshots
  # --------------------------------------------------------------------------------------

  # systemd.services.backups-snapshot = {
  #   enable = true;
  #   description = "Sync backup snapshot to nas";
  #   serviceConfig = {
  #     Type = "oneshot";
  #   };
  #   script = ''
  #     ${pkgs.rsync}/bin/rsync -avzP --delete /home/homefree/DockerData /mnt/Backups/snapshots/homefree/
  #   '';
  # };
  #
  # systemd.timers.backups-snapshot = {
  #   wantedBy = [ "timers.target" ];
  #   partOf = [ "snapshot-to-nas.service" ];
  #   timerConfig = {
  #     OnCalendar = "daily";
  #     Unit = "snapshot-to-nas.service";
  #   };
  # };

  # --------------------------------------------------------------------------------------
  # Incremental Backups
  # --------------------------------------------------------------------------------------

  services.restic.backups = lib.mkMerge ([
    (lib.listToAttrs (lib.map (entry:
    {
      name = "local-${entry.label}";
      value = {
        initialize = true;
        passwordFile = config.homefree.backups.secrets.restic-password;
        # What to backup
        paths = entry.paths;
        # the name of the repository
        repository = backup-to-path + "/${entry.label}";
        timerConfig = {
          OnCalendar = "daily";
        };

        # Keep 7 daily, 5 weekly, and 10 annual backups
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-yearly 10"
        ];
      };
    }
    ) backup-from-paths))
    (lib.listToAttrs (lib.map (entry:
    {
      name = "backblaze-${entry.label}";
      value = {
        initialize = true;
        passwordFile = "/run/secrets/backup/restic-password";
        # environmentFile = "/run/secrets/backup/restic-env";
        # What to backup
        paths = entry.paths;
        # the name of the repository
        repository = "b2:${entry.label}";
        timerConfig = {
          OnCalendar = "daily";
        };

        # Keep 7 daily, 5 weekly, and 10 annual backups
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-yearly 10"
        ];
      };
    }
    ) backup-from-paths))
  ]);

  systemd.services = lib.listToAttrs (lib.map (entry: {
    name = "restic-backups-local-${entry.label}";
    value = {
      serviceConfig =
      let
        preStart = ''
          ## Make sure backup path exists
          mkdir -p "${backup-to-path + "/${entry.label}"}"

        '' + (if (lib.hasAttr entry.label service-to-postgres-databases-map) then
        (lib.concatStrings (lib.map (database:
        ''
          ## Dump postgres DB
          ## This could also be controlled by setting
          ## PartOf=restic-backups-local-${entry.label} in the postgresBackup-${database} settings
          systemctl restart postgresqlBackup-${database}

          mkdir -p "/var/backup/postgresql-homefree/${entry.label}"
          cp -rf "/var/backup/postgresql/${database}.sql.gz" "/var/backup/postgresql-homefree/${entry.label}/"
        '') service-to-postgres-databases-map.${entry.label}))
        else "");
      in
      {
        ## Must use lib.mkBefore to make sure path is created before other ExecStartPre scripts are run
        ExecStartPre = lib.mkBefore [ "!${pkgs.writeShellScript "restic-backups-to-local-${entry.label}" preStart}" ];
      };
    };
  }
  ) backup-from-paths);
}


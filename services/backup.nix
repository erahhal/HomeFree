## 3-2-1 Backup strategy
## 3 copies of data - original plus 2 copies
## 2 different devices or media types
## 1 offsite backup
{ config, lib, pkgs, ... }:
let
  trimTrailingSlash = s: lib.head (lib.match "(.*[^/])[/]*" s);
  backup-to-path = trimTrailingSlash config.homefree.backups.to-path;
  ## Combine service backup paths to extra custom paths into an array of { label = "label"; paths = []; }
  backup-from-paths-all =
    (lib.map (entry: {
      label = entry.label;
      paths = entry.backup.paths
        ## Add postgres database backup paths
        ++ (if (lib.length entry.backup.postgres-databases) > 0 then [ "/var/backup/postgresql-homefree/${entry.label}" ] else [])
        ## Add mysql database backup paths
        ++ (if (lib.length entry.backup.mysql-databases) > 0 then [ "/var/backup/mysql-homefree/${entry.label}" ] else []);
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
  mysql-databases = lib.flatten (lib.map (entry: entry.backup.mysql-databases) config.homefree.service-config);
  service-to-mysql-databases-map  = lib.listToAttrs (lib.map (entry: {
    name = entry.label;
    value = entry.backup.mysql-databases;
  }) config.homefree.service-config);
  quoted-backup-path-list = lib.concatStringsSep " " (lib.map (entry: ''"${backup-to-path}/${entry.label}"'') backup-from-paths);
  backup-cli = pkgs.writeShellScriptBin "backup-cli" ''
    RESTIC_PASSWORD=$(cat /run/secrets/backup/restic-password)
    export RESTIC_PASSWORD

    backup_paths=(${quoted-backup-path-list})

    for backup_path in "''\${backup_paths[@]}"
    do
      export RESTIC_REPOSITORY="''\${backup_path}"
      sudo --preserve-env=RESTIC_REPOSITORY --preserve-env=RESTIC_PASSWORD restic ls latest
    done
  '';
  backup-mysql-script =
  let
    cfg = config.services.mysqlBackup;
  in
    db: ''
      dest="${cfg.location}/${db}.gz"
      if ${pkgs.mariadb}/bin/mysqldump ${lib.optionalString cfg.singleTransaction "--single-transaction"} ${db} | ${pkgs.gzip}/bin/gzip -c ${cfg.gzipOptions} > $dest.tmp; then
        mv $dest.tmp $dest
        echo "Backed up to $dest"
      else
        echo "Failed to back up to $dest"
        rm -f $dest.tmp
        failed="$failed ${db}"
      fi
    '';
in
{
  ## Typical rsync command
  ## rsync -avzP --delete --no-links src dest

  ## To see files in backup
  ## sudo restic ls latest -r local:<backup path>

  environment.systemPackages = [
    pkgs.restic
    pkgs.rclone
    backup-cli
  ];

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
  # Mysql Dumps
  # --------------------------------------------------------------------------------------

  ## This service is only used for its config, but not actually run backups
  ## @TODO: Discard this
  services.mysqlBackup = {
    enable = config.homefree.backups.enable;
    ## Default location. Just repeated here for reference and stability.
    location = "/var/backup/mysql";
    databases = mysql-databases;
    ## This isn't really used, as backups are kicked off by restic below,
    ## so select the least frequent period.
    calendar = "01-01-01";
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
    # (lib.listToAttrs (lib.map (entry:
    # {
    #   name = "backblaze-${entry.label}";
    #   value = {
    #     initialize = true;
    #     passwordFile = "/run/secrets/backup/restic-password";
    #     environmentFile = "/run/secrets/backup/restic-environment";
    #     # What to backup
    #     paths = entry.paths;
    #     # the name of the repository
    #     repository = "b2:${entry.label}";
    #     timerConfig = {
    #       OnCalendar = "daily";
    #     };
    #
    #     # Keep 7 daily, 5 weekly, and 10 annual backups
    #     pruneOpts = [
    #       "--keep-daily 7"
    #       "--keep-weekly 5"
    #       "--keep-yearly 10"
    #     ];
    #   };
    # }
    # ) backup-from-paths))
    # (if config.homefree.backups.backblaze.enable then {
    #   "backblaze-${config.homefree.backups.backblaze.bucket}" = {
    #     initialize = true;
    #     passwordFile = "/run/secrets/backup/restic-password";
    #     environmentFile = "/run/secrets/backup/restic-environment";
    #     # What to backup
    #     paths = [
    #       backup-to-path
    #     ];
    #     # the name of the repository
    #     repository = "b2:${config.homefree.backups.backblaze.bucket}";
    #     timerConfig = {
    #       OnCalendar = "daily";
    #     };
    #
    #     # Keep 7 daily, 5 weekly, and 10 annual backups
    #     pruneOpts = [
    #       "--keep-daily 7"
    #       "--keep-weekly 5"
    #       "--keep-yearly 10"
    #     ];
    #   };
    # } else {})
  ]);

  # Create mount point
  systemd.tmpfiles.rules = [
    "d /mnt/backup-backblaze 0750 root root -"
  ];

  systemd.services = lib.listToAttrs (
    (lib.map (entry: {
    name = "restic-backups-local-${entry.label}";
    value = {
      serviceConfig =
      let
        preStart = ''
          ## Make sure backup path exists
          mkdir -p "${backup-to-path + "/${entry.label}"}"

        ''
        +
        (if (lib.hasAttr entry.label service-to-postgres-databases-map) then
          (lib.concatStrings
            (lib.map
              (database: ''
                ## Dump postgres DB
                ## This could also be controlled by setting
                ## PartOf=restic-backups-local-${entry.label} in the postgresBackup-${database} settings
                systemctl restart postgresqlBackup-${database}

                mkdir -p "/var/backup/postgresql-homefree/${entry.label}"
                cp -rf "/var/backup/postgresql/${database}.sql.gz" "/var/backup/postgresql-homefree/${entry.label}/"

              '')
              service-to-postgres-databases-map.${entry.label}
            )
          )
        else
          ""
        )
        +
        (if (lib.hasAttr entry.label service-to-mysql-databases-map) then
          (lib.concatStrings
            (lib.map
              (database: ''
                ${backup-mysql-script database}

                mkdir -p "/var/backup/mysql-homefree/${entry.label}"
                cp -rf "/var/backup/mysql/${database}.gz" "/var/backup/mysql-homefree/${entry.label}/"

              '')
              service-to-mysql-databases-map.${entry.label}
            )
          )
        else
          ""
        );
      in
      {
        ## Must use lib.mkBefore to make sure path is created before other ExecStartPre scripts are run
        ExecStartPre = lib.mkBefore [ "!${pkgs.writeShellScript "restic-backups-to-local-${entry.label}" preStart}" ];
      };
    };
  }
  ) backup-from-paths)
  ++ (if config.homefree.backups.backblaze.enable == true then [
  {
    name = "rclone-backblaze";
    value = {
      description = "Mount Backblaze B2 bucket";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "notify";
        ExecStartPre = [
          "${pkgs.writeShellScript "create-rclone-config" ''
            mkdir -p /root/.config/rclone
            cat > /root/.config/rclone/rclone.conf << EOF
            [b2]
            type = b2
            account = $(cat ${config.homefree.backups.secrets.backblaze-id})
            key = $(cat ${config.homefree.backups.secrets.backblaze-key})
            EOF
          ''}"
        ];
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount \
            --config /root/.config/rclone/rclone.conf \
            --vfs-cache-mode full \
            --vfs-cache-max-age 24h \
            --log-level INFO \
            --log-file /var/log/rclone.log \
            --allow-non-empty \
            b2:${config.homefree.backups.backblaze.bucket} /mnt/backup-backblaze
        '';
        ExecStop = "${pkgs.fuse}/bin/fusermount -u /mnt/backup-backblaze";
        Restart = "on-failure";
        RestartSec = "10s";
        RemainAfterExit = "yes";
        User = "root";
      };
    };
  }
  {
    name = "restic-backblaze-rsync";
    value = {
      description = "Sync local restic backup to Backblaze";
      after = [ "rclone-backblaze.service" ];
      requires = [ "rclone-backblaze.service" ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = "${pkgs.rsync}/bin/rsync -av --delete ${backup-to-path}/ /mnt/backup-backblaze";
      };
    };
  }
  ] else []));

  systemd.timers = if config.homefree.backups.backblaze.enable == true then {
    restic-backblaze-rsync = {
      wantedBy = [ "timers.target" ];
      after = [ "rclone-backblaze.service" ];
      requires = [ "rclone-backblaze.service" ];

      timerConfig = {
        OnCalendar = "03:00";
        RandomizedDelaySec = "30m";
        Persistent = true;
      };
    };
  } else {};
}

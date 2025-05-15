{
  config,
  pkgs,
  ...
}: let
  inherit (pkgs) lib;
in {
  services.restic.backups."${config.networking.hostName}" = {
    createWrapper = true;
    initialize = true;
    repository = "sftp:root@talos.lan:/mnt/data/backup/restic/${config.networking.hostName}";
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
      "--keep-yearly 3"
    ];
    dynamicFilesFrom = "";
    passwordFile = config.sops.secrets.restic_password.path;
    paths = [
      "/var"
      "/home"
      "/root"
      "/etc"
      "/boot"
    ];
    exclude = [
      "/var/cache"
      "/var/tmp"
      "/var/run"
      "/var/lib/docker/*"
      "/var/lib/containerd/*"
      "/var/lib/lxd/*"
      "/home/*/.cache"
      "/home/*/.cargo/registry"
    ];
    timerConfig = {
      OnCalendar = lib.mkDefault "daily";
      Persistent = true;
    };
  };
}

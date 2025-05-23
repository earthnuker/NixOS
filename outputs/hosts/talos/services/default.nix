{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./caddy
    ./duckdns.nix
    ./glances
    ./homepage
    ./monitoring
    ./nats.nix
    ./postgresql.nix
    ./recyclarr
    ./searxng.nix
    # ./kanidm.nix
    ./printing.nix
    ./weechat.nix
    ./forgejo.nix
    ./lldap.nix
    ./dns.nix
    ./glance.nix
  ];
  systemd.tmpfiles.rules = [
    "v /.snapshots - - -"
  ];
  hive.services = {
    tvstack = {
      enable = false;
    };
  };

  users.users.immich.extraGroups = ["video" "render"];

  services = {
    immich = {
      enable = true;
      accelerationDevices = null;
      host = "127.0.0.1";
      port = 2283;
      # mediaLocation = "/mnt/data/media/photos";
    };
    thelounge = {
      enable = true;
      port = 3333;
      plugins = with pkgs.theLoungePlugins; [
        # TODO: re-add themes
        # themes.midnight
      ];
      extraConfig = {
        defaults = {
          name = "BJZ";
          host = "irc.bonerjamz.us";
          port = 6697;
        };
      };
    };
    zfs = {
      autoSnapshot.enable = false;
      autoScrub = {
        enable = true;
        interval = "*-*-1 23:00";
      };
    };
    sanoid = {
      enable = true;
      templates.backup = {
        hourly = 24;
        daily = 30;
        monthly = 12;
        autoprune = true;
        autosnap = true;
      };
      datasets."zpool/data" = {
        useTemplate = ["backup"];
      };
    };
    snapper = {
      snapshotRootOnBoot = true;
      persistentTimer = true;
      configs.root = {
        SUBVOLUME = "/";
        # create hourly snapshots
        TIMELINE_CREATE = true;

        # cleanup hourly snapshots after some time
        TIMELINE_CLEANUP = true;

        # limits for timeline cleanup
        TIMELINE_MIN_AGE = 1800;
        TIMELINE_LIMIT_HOURLY = 24;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 12;
        TIMELINE_LIMIT_YEARLY = 3;
      };
    };
    ucodenix.enable = true;
    openssh.openFirewall = true;
    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
    fstrim.enable = true;
    fwupd.enable = true;
    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      authKeyFile = config.sops.secrets.tailscale_auth.path;
      permitCertUid = "caddy";
      extraUpFlags = ["--ssh" "--accept-dns"];
    };
    tailscaleAuth = {
      enable = true;
      user = "caddy";
      group = "caddy";
    };

    resolved.enable = true;

    samba = {
      enable = true;
      openFirewall = true;
      settings.data = {
        path = "/mnt/data";
        writeable = "yes";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "root";
        "force group" = "root";
      };
      settings.global = {
        "workgroup" = "WORKGROUP";
        "server string" = "talos";
        "netbios name" = "talos";
        "security" = "user";
        "hosts allow" = "192.168.0. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
    };
  };
}

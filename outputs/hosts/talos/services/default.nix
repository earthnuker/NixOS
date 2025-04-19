{config, ...}: {
  imports = [
    ./caddy.nix
    ./duckdns.nix
    ./glances
    ./homepage
    ./monitoring.nix
    ./nats.nix
    ./postgresql.nix
    ./recyclarr
    ./searxng.nix
    ./authentik.nix
  ];
  services = {
    immich = {
      enable = true;
      accelerationDevices = null;
      host = "127.0.0.1";
      port = 2283;
      # mediaLocation = "/mnt/data/media/photos";
    };
    zfs = {
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

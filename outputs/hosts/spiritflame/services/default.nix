{config, ...}: {
  imports = [
    ./caddy.nix
    ./duckdns.nix
    ./recyclarr
  ];
  services = {
    zfs.autoScrub.enable = true;
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

    homepage-dashboard = {
      enable = true;
      openFirewall = true;
      services = import ./homepage.nix;
      docker = {
        local = {
          host = "127.0.0.1";
          port = 2375;
        };
      };
    };

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
        "server string" = "spiritflame";
        "netbios name" = "spiritflame";
        "security" = "user";
        "hosts allow" = "192.168.0. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
    };
  };
}

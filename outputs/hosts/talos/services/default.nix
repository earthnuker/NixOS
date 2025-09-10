{
  config,
  users,
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
    ./printing.nix
    ./weechat.nix
    ./forgejo.nix
    ./lldap.nix
    ./dns.nix
    ./glance.nix
    ./gollum.nix
    ./pinchflat.nix
    ./paperless.nix
    ./samba.nix
    # ./kanidm.nix
    #./wikijs.nix
    #./tandoor.nix
    users.coolbug
  ];

  hive.services = {
    tvstack = {
      enable = false;
    };
  };

  systemd.tmpfiles.rules = [
    "v /.snapshots - - -"
  ];
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  services = {
    immich = {
      enable = true;
      accelerationDevices = null;
      host = "127.0.0.1";
      port = 2283;
      # mediaLocation = "/mnt/data/media/photos";
    };
    ttyd = {
      enable = true;
      writeable = true;
    };
    thelounge = {
      enable = true;
      port = 3333;
      extraConfig = {
        defaults = {
          name = "BJZ";
          host = "irc.bonerjamz.us";
          port = 6697;
        };
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
      extraUpFlags = [
        "--ssh"
        "--accept-dns"
      ];
    };
    tailscaleAuth = {
      enable = true;
      user = "caddy";
      group = "caddy";
    };

    resolved.enable = true;
  };
}

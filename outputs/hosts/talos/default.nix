{
  modulesPath,
  pkgs,
  lib,
  inputs,
  config,
  ...
}: {
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    ./disk-config
    # ./hardware-configuration.nix
    ./networking.nix
    ./containers
    ./services
    ./quicksync.nix
    ./topology.nix
    ./limits.nix
    # ./power.nix
  ];
  facter.reportPath = ./facter.json;
  sops.secrets = {
    duckdns_token.restartUnits = [
      "duckdns.service"
    ];
    tailscale_auth.restartUnits = [
      "tailscaled.service"
      "tailscaled-autoconnect.service"
    ];
    radarr_api_key.restartUnits = [
      "recyclarr.service"
    ];
    sonarr_api_key.restartUnits = [
      "recyclarr.service"
    ];
    searxng_env.restartUnits = [
      "searx-init.service"
      "searx"
    ];
    vpn_env.restartUnits = [
      "arion-tvstack.service"
    ];
    rescrap_tailscale_auth.restartUnits = [
      "container@chimera.service"
    ];
  };

  systemd.sleep.extraConfig = lib.mkForce "";

  programs.nix-index-database.comma.enable = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [
        "@wheel"
        "root"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  time.timeZone = "Europe/Berlin";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    zfs
    fastfetch
    htop
    nh
    podman-tui
    dive
    comma
    ripgrep
    tmux
    neovim
    inxi
    molly-guard
  ];

  programs.rust-motd = {
    enable = true;
    enableMotdInSSHD = true;
    order = [
      "banner"
      "uptime"
      "load_avg"
      "memory"
      "filesystems"
      "service_status"
      "last_login"
    ];
    settings = {
      banner = {
        color = "red";
        command = ''
          hostname | ${lib.getExe pkgs.figlet} -f slant
        '';
      };
      service_status = {
        Tailscale = "tailscaled";
        "Prometheus Exporter" = "prometheus-node-exporter";
        Grafana = "grafana";
        Immich = "immich-server";
        Podman = "podman";
        NATS = "nats";
        SMB = "samba-smbd";
        SSH = "sshd";
        Caddy = "caddy";
      };
      load_avg = {
        format = "Load (1, 5, 15 min.): {one:.02}, {five:.02}, {fifteen:.02}";
      };
      uptime = {
        prefix = "Up";
      };
      filesystems = {
        root = "/";
        boot = "/boot";
        data = "/mnt/data";
      };
      memory = {
        swap_pos = "beside";
      };
      last_login = {
        root = 2;
      };
    };
  };

  users.users.root = {
    hashedPasswordFile = config.sops.secrets.talos_root_passwd.path;
    openssh.authorizedKeys.keyFiles = [inputs.ssh-keys-earthnuker.outPath];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICQP9/reHoakHb/tcF9YDspdUE+epG/gmU8yLrA3Jh7d root@godwaker"
    ];
    extraGroups = [
      "video"
      "render"
      "podman"
      "docker"
    ];
  };

  boot = {
    supportedFilesystems = [
      "zfs"
      "ntfs"
      "exfat"
    ];
    kernelModules = ["intel_rapl_common"];
    zfs.devNodes = "/dev/disk/by-path";
    kernelParams = ["microcode.amd_sha_check=off"];
  };
  system.stateVersion = "24.05";
}

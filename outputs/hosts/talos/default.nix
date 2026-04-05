{
  modulesPath,
  pkgs,
  lib,
  inputs,
  config,
  users,
  root,
  sources,
  ...
}: {
  sops.secrets.talos_root_passwd = {};
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
    ./shell.nix
    # ./power.nix
    # users.earthnuker
    users.coolbug
  ];

  facter.reportPath = ./facter.json;
  documentation = {
    enable = true;
    dev.enable = true;
    doc.enable = true;
    info.enable = true;
    man.enable = true;
    nixos.enable = true;
  };

  programs = {
    nix-index-database.comma.enable = true;
    mosh.enable = true;
    fish = {
      enable = true;
      vendor = {
        completions.enable = true;
        config.enable = true;
        functions.enable = true;
      };
    };
  };
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
      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://cache.lix.systems"
        "https://noctalia.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
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
    helix
    inxi
    molly-guard
    bat
    carapace
    btop
    rom
  ];
  environment.shellAliases = {
    "cat" = "bat -pp";
    "zstatus" = "zpool status;zpool list; zfs list -o name,used,usedbychildren,usedbydataset,usedbysnapshots,avail,refer";
  };
  programs.rust-motd = {
    enable = false;
    enableMotdInSSHD = false;
    order = [
      "global"
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
        backups = "/mnt/data/backup";
        media = "/mnt/data/media";
      };
      memory = {
        swap_pos = "beside";
      };
      last_login = {
        root = 2;
      };
    };
  };
  programs.bash.interactiveShellInit = ''
    ${lib.getExe pkgs.dfc} -l -p /dev,zpool -q name -T -d
  '';
  users.users = {
    root = {
      hashedPasswordFile = config.sops.secrets.talos_root_passwd.path;
      openssh.authorizedKeys.keyFiles = [inputs.ssh-keys-earthnuker.outPath];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICQP9/reHoakHb/tcF9YDspdUE+epG/gmU8yLrA3Jh7d root@godwaker"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJG2CElVLBAG2MBde50PYg7y+BGV5y6fdvemFBuQiI1K earthnuker@godwaker"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJeIHgefF8KgH0xl9LgDU5pZZ3tef/G/+jKQmKEmkzen"
      ];
      extraGroups = [
        "video"
        "render"
        "podman"
        "docker"
      ];
      shell = pkgs.fish;
    };
    earthnuker.isNormalUser = true;
  };
  home-manager = {
    extraSpecialArgs = {
      inherit inputs sources root;
      host-config = config;
    };
    useGlobalPkgs = false;
    useUserPackages = true;
    verbose = true;
    backupFileExtension = "hm_bak";
  };

  boot = {
    supportedFilesystems = [
      "zfs"
      "ntfs"
      "exfat"
    ];
    kernelModules = ["intel_rapl_common"];
    zfs = {
      devNodes = "/dev/disk/by-id";
      forceImportRoot = false;
    };
    kernelParams = ["microcode.amd_sha_check=off"];
  };
  system.stateVersion = "24.05";
}

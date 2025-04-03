{
  modulesPath,
  pkgs,
  lib,
  inputs,
  drives,
  config,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disk-config
    ./hardware-configuration.nix
    ./networking.nix
    ./containers
    ./services
    # ./quicksync.nix
  ];

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
    searxng_env.restartUnits = ["searx-init.service" "searx"];
    vpn_env.restartUnits = [
      "arion-tvstack.service"
    ];
  };

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
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
  ];

  virtualisation.docker = {
    enable = true;
    logDriver = "journald";
    daemon.settings = {
      data-root = "/mnt/data/docker";
      hosts = [
        "tcp://127.0.0.1:2375"
        "unix:///var/run/docker.sock"
      ];
    };
  };

  users.users.root = {
    initialPassword = "toor";
    openssh.authorizedKeys.keyFiles = [inputs.ssh-keys-earthnuker.outPath];
    extraGroups = ["video" "render"];
  };

  boot.supportedFilesystems = ["zfs"];
  boot.zfs.devNodes = "/dev/disk/by-path";
  system.stateVersion = "24.05";
}

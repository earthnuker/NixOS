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
    ./quicksync.nix
    ./topology.nix
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

  systemd.sleep.extraConfig = lib.mkForce "";

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
    fastfetch
    htop
    nh
    podman-tui
    dive
  ];

  users.users.root = {
    hashedPasswordFile = config.sops.secrets.talos_root_passwd.path;
    openssh.authorizedKeys.keyFiles = [inputs.ssh-keys-earthnuker.outPath];
    extraGroups = ["video" "render" "podman" "docker"];
  };

  users.users.immich.extraGroups = ["video" "render"];

  boot.supportedFilesystems = ["zfs"];
  boot.kernelModules = ["intel_rapl_common"];
  boot.zfs.devNodes = "/dev/disk/by-path";
  system.stateVersion = "24.05";
}

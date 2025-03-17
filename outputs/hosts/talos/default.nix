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
  ];

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

  system.stateVersion = "24.05";
}

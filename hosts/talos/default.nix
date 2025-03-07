{
  modulesPath,
  pkgs,
  lib,
  inputs,
  drives,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (import ./disk-config {
      inherit lib drives;
    })
    ./hardware-configuration.nix
    ./networking.nix
    ./containers
    ./caddy.nix
  ];

  facter.reportPath = ./facter.json;

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

  nixpkgs.config.allowUnfree = true;

  services = {
    zfs.autoScrub.enable = true;
  };

  environment.systemPackages = with pkgs; [
    zfs
  ];

  virtualisation.docker = {
    enable = true;
    logDriver = "journald";
    daemon.settings = {
      data-root = "/tank/docker";
    };
  };

  users.users.root = {
    initialPassword = "toor";
    openssh.authorizedKeys.keyFiles = [inputs.ssh-keys-earthnuker.outPath];
  };

  boot.supportedFilesystems = ["zfs"];
  boot.zfs.devNodes = "/dev/disk/by-path";
  system.stateVersion = "24.05";
}

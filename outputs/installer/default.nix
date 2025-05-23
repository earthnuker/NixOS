{
  config,
  lib,
  pkgs,
  inputs,
  ssh-keys-earthnuker,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"
  ];
  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };
  environment.systemPackages = with pkgs; [
    nixos-install-tools
    inputs.nixos-facter.packages."x86_64-linux".nixos-facter
    disko
    sbctl
  ];
  isoImage.squashfsCompression = "zstd";
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    extraOptions = "experimental-features = nix-command flakes";
  };
  services.getty.autologinUser = lib.mkForce "root";
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
  networking = {
    hostName = "nixos-installer";
    tempAddresses = "disabled";
    networkmanager.enable = true;
    wireless.enable = false;
  };

  users.users.root = {
    openssh.authorizedKeys.keyFiles = [
      inputs.ssh-keys-earthnuker.outPath
    ];
  };

  systemd = {
    services.sshd.wantedBy = pkgs.lib.mkForce ["multi-user.target"];
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };
  system.stateVersion = "24.05";
}

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };
  environment.systemPackages = with pkgs; [
    nixos-install-tools
    inputs.nixos-facter.packages."x86_64-linux".nixos-facter
    disko
  ];
  isoImage.squashfsCompression = "zstd";
  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    extraOptions = "experimental-features = nix-command flakes";
  };
  services.getty.autologinUser = lib.mkForce "root";
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
  networking = {
    hostName = "nixos-installer";
    tempAddresses = "disabled";
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

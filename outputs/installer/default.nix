{
  config,
  lib,
  pkgs,
  ...
}: {
  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };
  isoImage.squashfsCompression = "zstd";
  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    extraOptions = "experimental-features = nix-command flakes";
  };

  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
  networking = {
    hostName = "nixos-installer";
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

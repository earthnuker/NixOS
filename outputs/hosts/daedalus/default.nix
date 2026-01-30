{modulesPath, ...}: {
  # imports = [
  #   "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  # ];
  nixpkgs.hostPlatform.system = "aarch64-linux";
  nixpkgs.buildPlatform.system = "x86_64-linux";
  # boot.loader.generic-extlinux-compatible.enable = true;
  # fileSystems."/" = {
  #   device = "/dev/disk/by-label/NIXOS_SD";
  #   fsType = "ext4";
  # };
  networking.hostName = "odroid-c2";
  networking.interfaces."eth0".useDHCP = true;

  boot.kernelParams = ["console=ttyAML0,115200n8"];
  # sdImage.compressImage = false;
  system.stateVersion = "25.05";
}

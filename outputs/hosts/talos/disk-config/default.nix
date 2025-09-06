{
  lib,
  vars,
  ...
} @ inputs: {
  imports = [
    ./services.nix
  ];
  disko.devices = {
    disk =
      (lib.genAttrs vars.drives.storage (device: import ./zpool_disk.nix {inherit device inputs;}))
      // {
        system = import ./system.nix {
          inherit inputs;
          drive = vars.drives.system;
        };
      };

    zpool = {
      zpool = import ./zpool.nix;
    };
  };
}

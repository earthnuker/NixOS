{
  drives,
  lib,
  ...
}: {
  disko.devices = {
    disk =
      (lib.genAttrs drives.storage (device: {
        type = "disk";
        name = device;
        device = "/dev/disk/by-id/${device}";
        content = {
          type = "zfs";
          pool = "zpool";
        };
      }))
      // {
        main = import ./system.nix {drive = drives.system;};
      };

    zpool = {
      zpool = import ./zpool.nix;
    };
  };
}

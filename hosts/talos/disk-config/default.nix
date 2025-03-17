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
          pool = "rpool";
        };
      }))
      // {
        system = import ./system.nix {drive = drives.system;};
      };

    zpool = {
      rpool = import ./zpool.nix;
    };
  };
}

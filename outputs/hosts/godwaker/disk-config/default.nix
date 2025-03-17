{drives, ...}: {
  disko.devices = {
    disk = {
      main = import ./system.nix {drive = drives.system;};
    };
  };
}

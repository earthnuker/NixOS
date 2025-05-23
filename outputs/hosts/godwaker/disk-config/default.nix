{vars, ...}: {
  disko.devices = {
    disk = {
      main = import ./system.nix {drive = vars.drives.system;};
    };
  };
}

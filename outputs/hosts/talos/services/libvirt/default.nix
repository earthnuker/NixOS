{
  services.cockpit = {
    enable = false;
    openFirewall = true;
  };
  services.imperativeContainment = {
    "windows" = {
      enable = false;
      osType = "windows";
      cores = 4;
      memoryMiB = 4 * 1024;
      createDiskIfMissing = true;
      diskSize = "100G";
      isoPath = "/mnt/data/Windows/Win10_22H2_EnglishInternational_x64v1.iso";
      graphics = "spice";
      enableTPM = true;
    };
  };
}

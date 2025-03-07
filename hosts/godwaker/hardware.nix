{pkgs, ...}: {
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;

      extraPackages = with pkgs; [
        intel-ocl
        intel-compute-runtime
        intel-media-driver
        vpl-gpu-rt
        vaapiVdpau
        libvdpau-va-gl
        (vaapiIntel.overrideAttrs (prev: {
          meta.priority = 1;
        }))
      ];
    };
  };
}

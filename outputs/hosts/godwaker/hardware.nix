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
        mesa
        intel-ocl
        intel-compute-runtime
        intel-media-driver
        intel-vaapi-driver
        vpl-gpu-rt
        libva-vdpau-driver
        # libvdpau-va-gl
        # (vaapiIntel.overrideAttrs (_prev: {
        #   meta.priority = 1;
        # }))
      ];
    };
  };
}

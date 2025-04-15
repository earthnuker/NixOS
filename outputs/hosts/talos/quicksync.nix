{pkgs, ...}: {
  hardware.firmware = [pkgs.linux-firmware];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      libva
      vaapiIntel
      vpl-gpu-rt
    ];
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
    LIBVA_MESSAGING_LEVEL = "1";
  };
}
/*
ffmpeg -y -v verbose \
-hwaccel qsv \
-hwaccel_output_format qsv \
-f lavfi -i testsrc=size=1920x1080:rate=30 \
-vf "scale_qsv=w=1920:h=1080" \
-c:v h264_qsv \
-preset veryslow \
-global_quality 18 \
-f matroska \
/dev/null
*/


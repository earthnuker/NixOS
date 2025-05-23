{
  pkgs,
  lib,
  vars,
  ...
}: let
  splash = pkgs.runCommand "splash.bmp" {nativeBuildInputs = with pkgs; [imagemagick];} ''
    convert \
      -verbose \
      -negate \
      -background black \
      -resize 256x256 \
      ${vars.bootsplash} \
      $out
  '';
in {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    kernelModules = ["rt2800usb"];
    plymouth = {
      enable = true;
      logo = splash;
      # theme = lib.mkForce "breeze";
    };
    #binfmt.emulatedSystems = ["aarch64-linux"];
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = lib.mkForce 0;
      systemd-boot = {
        enable = lib.mkForce false;
        configurationLimit = 10;
        consoleMode = "auto";
        editor = false;
        memtest86.enable = true;
        netbootxyz.enable = true;
      };
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    tmp = {
      useTmpfs = true;
      cleanOnBoot = true;
    };
    kernelParams = [
      # Silent Boot
      "quiet"
      "splash"
      "vga=current"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "microcode.amd_sha_check=off"
      # Audit
      # "audit=1"
    ];
    consoleLogLevel = 0;
    initrd = {
      systemd = {
        enable = true;
        tpm2.enable = true;
      };
      # https://github.com/NixOS/nixpkgs/pull/108294
      verbose = false;
      availableKernelModules = [
        "aesni_intel"
        "cryptd"
        "tpm_tis"
      ];
    };
  };
}

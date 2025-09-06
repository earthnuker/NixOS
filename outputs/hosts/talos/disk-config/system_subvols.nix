{drive}: {
  device = "/dev/disk/by-id/${drive}";
  type = "disk";
  content = {
    type = "gpt";
    partitions = {
      ESP = {
        type = "EF00";
        size = "512M";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = ["umask=0077"];
        };
      };
      root = {
        size = "100%";
        content = {
          type = "btrfs";
          subvolumes = {
            "/root" = {
              mountpoint = "/";
              mountOptions = [
                "compress=zstd"
                "noatime"
              ];
            };
            "/nix" = {
              mountpoint = "/nix";
              mountOptions = [
                "compress=zstd"
                "noatime"
              ];
            };
          };
          extraArgs = [
            "-f"
            "-L system"
          ]; # Override existing partition
        };
      };
      swap = {
        size = "32G";
        content = {
          type = "swap";
          discardPolicy = "both";
          randomEncryption = true;
          resumeDevice = true; # resume from hiberation from this device
        };
      };
    };
  };
}

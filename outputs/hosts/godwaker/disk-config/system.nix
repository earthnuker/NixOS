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
          mountOptions = [
            "defaults"
            "umask=0077"
          ];
        };
      };
      root = {
        end = "-16G";
        content = {
          type = "filesystem";
          format = "btrfs";
          extraArgs = ["-f"]; # Override existing partition
          mountpoint = "/";
          mountOptions = ["compress=zstd" "noatime"];
        };
      };
      swap = {
        size = "100%";
        content = {
          type = "swap";
          randomEncryption = true;
          resumeDevice = true;
        };
      };
    };
  };
}

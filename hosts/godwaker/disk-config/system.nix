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
          type = "filesystem";
          format = "btrfs";
          extraArgs = ["-f"]; # Override existing partition
          mountpoint = "/";
          mountOptions = ["compress=zstd" "noatime"];
        };
      };
    };
  };
}

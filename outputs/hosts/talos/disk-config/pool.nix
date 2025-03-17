{
  type = "mdadm";
  level = 5;
  content = {
    type = "gpt";
    partitions = {
      pool = {
        size = "100%";
        content = {
          extraArgs = ["-f"];
          type = "btrfs";
          subvolumes = {
            "/nix" = {
              mountpoint = "/nix";
              mountOptions = [
                "compress=zstd"
                "noatime"
              ];
            };
            "/data" = {
              mountpoint = "/mnt/data";
              mountOptions = [
                "compress=zstd"
                "noatime"
              ];
            };
          };
        };
      };
    };
  };
}

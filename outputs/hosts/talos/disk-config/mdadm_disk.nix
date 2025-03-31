{device}: {
  type = "disk";
  name = device;
  device = "/dev/disk/by-id/${device}";
  content = {
    type = "gpt";
    partitions = {
      mdraid = {
        size = "100%";
        content = {
          type = "mdraid";
          name = "pool";
        };
      };
    };
  };
}

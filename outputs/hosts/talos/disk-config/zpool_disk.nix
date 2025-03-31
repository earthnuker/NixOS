{device}: {
  type = "disk";
  name = device;
  device = "/dev/disk/by-id/${device}";
  content = {
    type = "zfs";
    pool = "zpool";
  };
}

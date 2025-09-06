{device, ...}: {
  type = "disk";
  name = device;
  destroy = false;
  device = "/dev/disk/by-id/${device}";
  content = {
    type = "zfs";
    pool = "zpool";
  };
}

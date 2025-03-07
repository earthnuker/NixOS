{
  type = "zpool";
  mode = "raidz1";
  options = {
    ashift = "12";
  };
  rootFsOptions = {
    acltype = "posixacl";
    atime = "off";
    compression = "lz4";
    mountpoint = "none";
    xattr = "sa";
    recordsize = "512K";
    "com.sun:auto-snapshot" = "false";
  };
  datasets = {
    data = {
      type = "zfs_fs";
      mountpoint = "/mnt/data";
      options.mountpoint = "legacy";
    };
  };
}

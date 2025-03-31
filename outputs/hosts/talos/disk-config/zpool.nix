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
    nix = {
      type = "zfs_fs";
      mountpoint = "/nix";
      mountOptions = [
        "acl"
        "noatime"
      ];
      options = {
        mountpoint = "legacy";
        compression = "zstd";
      };
    };
    data = {
      type = "zfs_fs";
      mountpoint = "/mnt/data";
      mountOptions = [
        "acl"
        "noatime"
      ];
      options.mountpoint = "legacy";
    };
  };
}

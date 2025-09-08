let
  dataset = name: {
    inherit name;
    value = {
      type = "zfs_fs";
      mountpoint = "/mnt/${name}";
      mountOptions = [
        "acl"
        "noatime"
      ];
      options.mountpoint = "legacy";
    };
  };
in {
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
  datasets = builtins.listToAttrs (
    builtins.map dataset [
      "data"
      "data/backup"
      "data/media"
    ]
  );
}

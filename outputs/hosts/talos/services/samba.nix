{
  services.samba = {
    enable = true;
    openFirewall = true;
    settings.data = {
      path = "/mnt/data";
      writeable = "yes";
      browseable = "yes";
      "read only" = "no";
      "guest ok" = "yes";
      "create mask" = "0644";
      "directory mask" = "0755";
      "force user" = "root";
      "force group" = "root";
      "vfs objects" = "shadow_copy2, catia";
      "catia:mappings" = "0x22:0xa8,0x2a:0xa4,0x2f:0xf8,0x3a:0xf7,0x3c:0xab,0x3e:0xbb,0x3f:0xbf,0x5c:0xff,0x7c:0xa6";

      # Configure the shadow_copy2 module for your ZFS snapshots
      "shadow:snapdir" = ".zfs/snapshot";
      "shadow:sort" = "desc";
      "shadow:format" = "_%Y-%m-%d_%H:%M:%S";
      "shadow:snapprefix" = "^autosnap";
      "shadow:delimiter" = "_";
      "shadow:localtime" = "no";
    };
    settings.global = {
      "workgroup" = "WORKGROUP";
      "server string" = "talos";
      "netbios name" = "talos";
      "security" = "user";
      "hosts allow" = "192.168.0. 127.0.0.1 localhost";
      "hosts deny" = "0.0.0.0/0";
      "guest account" = "nobody";
      "map to guest" = "bad user";
    };
  };
}

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

{
  zfs.autoScrub.enable = true;
  samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;
    shares.tank = {
      path = "/tank";
      writeable = "yes";
      browseable = "yes";
    };
    shares.global = {
      "server min protocol" = "SMB2_02";
    };
  };
}
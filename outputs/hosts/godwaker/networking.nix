_: {
  networking = {
    hostName = "godwaker-test";
    firewall.enable = false;
    networkmanager = {
      enable = true;
      wifi = {
        macAddress = "stable";
        backend = "iwd";
      };
    };
  };
}

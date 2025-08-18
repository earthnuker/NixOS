_: {
  networking = {
    hostName = "godwaker";
    useNetworkd = true;
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

{...}: {
  networking = {
    hostName = "godwaker";
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

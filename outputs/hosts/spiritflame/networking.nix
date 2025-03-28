{...}: {
  networking = {
    hostName = "spiritflame";
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [22 80 443];
    };
  };
}

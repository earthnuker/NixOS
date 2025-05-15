_: {
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [53];
  };
  services.dnsmasq = {
    enable = true;
    settings = {
    };
  };
}

{...}: {
  networking = {
    hostName = "talos";
    firewall.enable = true;
    firewall.allowPing = true;
    firewall.allowedTCPPorts = [22 80];
  };
}

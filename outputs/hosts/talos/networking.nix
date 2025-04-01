{...}: {
  networking = {
    hostName = "talos";
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
        80
        443
        4242 # quassel
      ];
    };
  };
}

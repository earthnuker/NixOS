_: {
  networking = {
    hostName = "talos";
    useNetworkd = true;
    interfaces = {};
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
        80
        443
        4242 # quassel
        4222 # NATS
      ];
    };
  };
}

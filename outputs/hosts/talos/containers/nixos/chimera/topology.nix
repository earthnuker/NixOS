{config, ...}: {
  topology.self = {
    services = {
      Ghidra = {
        name = "Ghidra";
        icon = "services.openssh";
        info = ":13100-13102";
      };
    };
    interfaces = {
      eth1 = {
        addresses = ["192.168.100.11"];
        network = "container_net";
        virtual = false;
        type = "ethernet";
      };
      tailscale0 = {
        network = "tailscale_rescrap";
        virtual = true;
        type = "wireguard";
        addresses = [config.networking.hostName];
        physicalConnections = [
          {
            node = "rescrap_ts";
            interface = "*";
          }
        ];
      };
    };
  };
}

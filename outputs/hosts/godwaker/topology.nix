{config, ...}: {
  topology.self = {
    name = "💻 ${config.networking.hostName}";
    hardware.info = "Thinkpad T470";
    services = {
      ssh = {
        name = "SSH";
        icon = "services.openssh";
        info = ":22";
      };
    };
    interfaces = {
      eth1 = {
        addresses = ["192.168.0.x (DHCP)"];
        network = "home";
        virtual = false;
        type = "ethernet";
      };
      wlan0 = {
        addresses = ["192.168.0.x (DHCP)"];
        network = "home";
        virtual = false;
        type = "wifi";
        physicalConnections = [
          {
            node = "router";
            interface = "wifi";
          }
        ];
      };
      tailscale0 = {
        addresses = [config.networking.hostName];
        network = "tailscale_home";
        type = "wireguard";
        virtual = true;
      };
    };
  };
}

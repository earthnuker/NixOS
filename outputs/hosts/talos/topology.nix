{
  config,
  lib,
  ...
}: {
  topology.self = {
    hardware.info = "NAS";
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
      tailscale0 = {
        network = "tailscale_home";
        virtual = true;
        type = "wireguard";
        addresses = [config.networking.hostName];
      };
    };
  };
}

{config, ...}: let
  inherit (config.lib.topology) mkInternet mkRouter mkConnection mkSwitch mkDevice;
in {
  nodes = {
    internet = mkInternet {
      connections = mkConnection "router" "wan";
    };
    router = mkRouter "Vodafone Station" {
      info = "Vodafone Station (ARRIS TG3442DE)";
      interfaceGroups = [
        ["eth1" "eth2" "eth3" "eth4" "eth5" "eth6" "wifi"]
        ["wan"]
      ];
      interfaces.eth1 = {
        addresses = ["192.168.0.1"];
        network = "home";
      };
      connections.eth1 = mkConnection "switch" "eth1";
      connections.eth2 = mkConnection "nightmaregreen" "eth1";
      connections.eth3 = mkConnection "talos" "eth1";
      connections.eth4 = mkConnection "godwaker" "eth1";
    };
    switch = mkSwitch "Office Switch" {
      info = "D-Link DGS-105";
      interfaceGroups = [["eth1" "eth2" "eth3" "eth4" "eth5"]];
      connections.eth2 = mkConnection "work-laptop" "eth1";
      connections.eth3 = mkConnection "dietpi" "eth1";
    };
    ghidra = mkDevice "Ghidra" {
      parent = "talos";
      guestType = "docker";
      info = "Ghidra Docker Container";
      interfaces = {
        eth1 = {
          addresses = [];
          network = "home";
          virtual = true;
          type = "ethernet";
        };
      };
      services = {
        ghidra = {
          name = "Ghidra";
          info = ":13100, :13101, :13102";
        };
      };
    };
    dietpi = mkDevice "Dietpi" {
      info = "ODROID C2";
      services = {
        ssh = {
          name = "SSH";
          icon = "services.openssh";
          info = ":22";
        };
      };
      interfaces = {
        eth1 = {
          addresses = ["192.168.0.2"];
          network = "home";
          virtual = false;
          type = "ethernet";
        };
        tailscale0 = {
          addresses = ["dietpi"];
          network = "tailscale_home";
          type = "wireguard";
          virtual = true;
          physicalConnections = [
            {
              node = "talos";
              interface = "tailscale0";
            }
            {
              node = "godwaker";
              interface = "tailscale0";
            }
            {
              node = "nightmaregreen";
              interface = "tailscale";
            }
            {
              node = "work-laptop";
              interface = "tailscale";
            }
            {
              node = "scorpionstare";
              interface = "tailscale";
            }
          ];
        };
      };
    };
    scorpionstare = mkDevice "Scorpionstare" {
      info = "OnePlus Nord";
      interfaces = {
        wlan = {
          addresses = ["192.168.0.x (DHCP)"];
          network = "home";
          type = "wifi";
        };
        tailscale = {
          addresses = ["scorpionstare"];
          network = "tailscale_home";
          type = "wireguard";
          virtual = true;
        };
      };
    };
    work-laptop = mkDevice "Work Laptop" {
      info = "DELL Laptop";
      # interfaceGroups = [["eth1"] ["wifi1"] ["tailscale"]];
      interfaces = {
        eth1 = {
          addresses = ["192.168.0.x (DHCP)"];
          network = "home";
          virtual = false;
          type = "ethernet";
        };
        tailscale = {
          addresses = ["work-laptop"];
          network = "tailscale_home";
          type = "wireguard";
          virtual = true;
        };
      };
    };
    nightmaregreen = mkDevice "Nightmaregreen" {
      info = "Desktop";
      interfaces = {
        eth1 = {
          addresses = ["192.168.0.17"];
          gateways = ["router"];
          network = "home";
          virtual = false;
          type = "ethernet";
        };
        tailscale = {
          addresses = ["nightmaregreen"];
          network = "tailscale_home";
          type = "wireguard";
          virtual = true;
        };
      };
    };
  };
  networks.home = {
    name = "Home Network";
    cidrv4 = "192.168.0.0/24";
  };
  networks.tailscale_home = {
    name = "Home Tailscale";
    cidrv4 = "100.64.0.0/10";
  };
  networks.tailscale_rescrap = {
    name = "ReScrap Tailscale";
    cidrv4 = "100.64.0.0/10";
  };
}

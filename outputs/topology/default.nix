{
  config,
  lib,
  ...
}: let
  inherit (config.lib.topology) mkInternet mkRouter mkConnection mkSwitch mkDevice;
  /* TODO: update to docker */
  tvstack_enabled = lib.hasAttr "tvstack" config.nixosConfigurations.talos.config.virtualisation.quadlet.pods;
in {
  nodes =
    {
      internet = mkInternet { };
      work =
        mkInternet {
          connections = mkConnection "work-laptop" "vpn1";
        }
        // {
          name = "Work Network";
        };
      rescrap =
        mkInternet {
          connections = mkConnection "ghidra" "tailscale";
        }
        // {
          name = "ReScrap Tailnet";
        };
      router = mkRouter "Vodafone Station" {
        info = "ARRIS TG3442DE";
        interfaceGroups = [
          ["lan" "wifi"]
          ["wan"]
        ];
        interfaces.lan = {
          addresses = ["192.168.0.1"];
          network = "home";
        };
        interfaces.wifi = {
          addresses = ["192.168.0.1"];
          network = "home";
        };
        connections.wan = mkConnection "internet" "*";
        connections.lan = mkConnection "router_switch" "eth0";
      };
      router_switch = mkSwitch "Router Switch" {
        info = "ARRIS TG3442DE internal switch";
        interfaceGroups = [["eth0" "eth1" "eth2" "eth3" "eth4" "eth5"]];
        connections.eth1 = mkConnection "office_switch" "eth1";
        connections.eth2 = mkConnection "nightmaregreen" "eth1";
        connections.eth3 = mkConnection "talos" "eth1";
      };
      office_switch = mkSwitch "Office Switch" {
        info = "D-Link DGS-105";
        image = ./images/dlink-dgs105.png;
        interfaceGroups = [["eth1" "eth2" "eth3" "eth4" "eth5"]];
        connections.eth2 = mkConnection "work-laptop" "eth1";
        connections.eth3 = mkConnection "dietpi" "eth1";
        connections.eth4 = mkConnection "godwaker" "eth1";
      };
      ghidra = mkDevice "🐉 Ghidra" {
        parent = "talos";
        guestType = "docker";
        info = "Ghidra Docker Container";
        interfaces = {
          eth1 = {
            addresses = [];
            network = "home";
            virtual = true;
            type = "ethernet";
            physicalConnections = [
              {
                node = "talos";
                interface = "eth1";
              }
            ];
          };
          tailscale = {
            addresses = ["ghidra"];
            network = "tailscale_rescrap";
            type = "wireguard";
            virtual = true;
            physicalConnections = [
              {
                node = "nightmaregreen";
                interface = "tailscale2";
              }
            ];
          };
        };
        services = {
          ghidra = {
            name = "Ghidra";
            info = ":13100, :13101, :13102";
          };
        };
      };
      dietpi = mkDevice "🥧 Dietpi" {
        info = "ODROID C2";
        services = {
          ssh = {
            name = "SSH";
            icon = "services.openssh";
            info = ":22";
          };
          pihole = {
            name = "PiHole";
            icon = ./images/pihole.png;
            info = ":80,:53";
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
                interface = "tailscale1";
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
      coolphone = mkDevice "📱 Coolphone" {
        info = "iPhone";
        interfaces = {
          wlan = {
            addresses = ["192.168.0.x (DHCP)"];
            network = "home";
            type = "wifi";
            physicalConnections = [
              {
                node = "router";
                interface = "wifi";
              }
            ];
          };
        };
      };
      coolbook = mkDevice "💻 Coolbook" {
        info = "Chromebook";
        interfaces = {
          wlan = {
            addresses = ["192.168.0.x (DHCP)"];
            network = "home";
            type = "wifi";
            physicalConnections = [
              {
                node = "router";
                interface = "wifi";
              }
            ];
          };
        };
      };
      scorpionstare = mkDevice "📱 Scorpionstare" {
        info = "OnePlus Nord";
        interfaces = {
          wlan = {
            addresses = ["192.168.0.x (DHCP)"];
            network = "home";
            type = "wifi";
            physicalConnections = [
              {
                node = "router";
                interface = "wifi";
              }
            ];
          };
          tailscale = {
            addresses = ["scorpionstare"];
            network = "tailscale_home";
            type = "wireguard";
            virtual = true;
          };
        };
      };
      work-laptop = mkDevice "💻 Work Laptop" {
        info = "DELL Laptop";
        interfaces = {
          eth1 = {
            addresses = ["192.168.0.x (DHCP)"];
            network = "home";
            virtual = false;
            type = "ethernet";
          };
          vpn1 = {
            network = "work";
            virtual = false;
            type = "tun";
          };
          tailscale = {
            addresses = ["work-laptop"];
            network = "tailscale_home";
            type = "wireguard";
            virtual = true;
          };
        };
      };
      nightmaregreen = mkDevice "🖥️ Nightmaregreen" {
        info = "Desktop";
        interfaces = {
          eth1 = {
            addresses = ["192.168.0.17"];
            gateways = ["router"];
            network = "home";
            virtual = false;
            type = "ethernet";
          };
          tailscale1 = {
            addresses = ["nightmaregreen"];
            network = "tailscale_home";
            type = "wireguard";
            virtual = true;
          };
          tailscale2 = {
            addresses = ["nightmaregreen"];
            network = "tailscale_rescrap";
            type = "wireguard";
            virtual = true;
          };
        };
      };
    }
    // (lib.optionalAttrs tvstack_enabled {
      tvstack = mkDevice "📺 Tvstack" {
        parent = "talos";
        guestType = "podman";
        info = "TVStack Podman";
        interfaces = {
          eth1 = {
            addresses = [];
            network = "home";
            virtual = true;
            type = "ethernet";
            physicalConnections = [
              {
                node = "talos";
                interface = "eth1";
              }
            ];
          };
          vpn = {
            addresses = [];
            type = "tun";
            virtual = true;
            physicalConnections = [
              {
                node = "internet";
                interface = "*";
              }
            ];
          };
        };
        services = {
          sonarr = {
            name = "Sonarr";
            icon = "services.sonarr";
          };
          radarr = {
            name = "Radarr";
            icon = "services.radarr";
          };
          prowlarr = {
            name = "Prowlarr";
            icon = "services.prowlarr";
          };
        };
      };
    });
  networks.home = {
    name = "Home Network";
    cidrv4 = "192.168.0.0/24";
  };
  networks.work = {
    name = "Work Network";
    cidrv4 = "192.168.1.0/24";
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

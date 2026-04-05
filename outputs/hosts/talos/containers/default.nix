{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  std = inputs.nix-std.lib;
  podman = lib.getExe config.virtualisation.podman.package;
  resolvectl = "${pkgs.systemd}/bin/resolvectl";
in {
  imports = [
    ./oci
    ./arion
    ./nixos
  ];
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      autoPrune = {
        enable = true;
        flags = [
          "--all"
          "--filter"
          "until=24h"
        ];
      };
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  systemd = {
    sockets.netavark-dhcp-proxy = {
      description = "Netavark DHCP proxy socket";
      wantedBy = ["sockets.target"];
      socketConfig = {
        ListenStream = "%t/podman/nv-proxy.sock";
        SocketMode = "0660";
      };
    };

    paths.podman-dns-resolved = {
      wantedBy = ["multi-user.target"];
      pathConfig.PathExists = "/sys/class/net/podman0";
    };

    services = {
      podman-dns-resolved = {
        description = "Route dns.podman lookups to Podman DNS";

        bindsTo = [
          "sys-subsystem-net-devices-podman0.device"
        ];

        after = [
          "systemd-resolved.service"
          "sys-subsystem-net-devices-podman0.device"
        ];

        requires = [
          "systemd-resolved.service"
        ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          gateway="$(
            ${podman} network inspect podman \
              --format '{{(index .Subnets 0).Gateway}}'
          )"

          ${resolvectl} dns podman0 "$gateway"
          ${resolvectl} domain podman0 '~dns.podman'
          ${resolvectl} default-route podman0 false
        '';
      };
      netavark-dhcp-proxy = {
        description = "Netavark DHCP proxy service";
        requires = ["netavark-dhcp-proxy.socket"];
        after = ["netavark-dhcp-proxy.socket"];
        serviceConfig = {
          Type = "exec";
          ExecStart = "${pkgs.netavark}/bin/netavark dhcp-proxy -a 30";
        };
      };
    };
  };

  environment.etc."containers/registries.conf.d/01-unqualified-docker.conf".text = std.serde.toTOML {
    unqualified-search-registries = [
      "ghcr.io"
      "quay.io"
      "gcr.io"
      "docker.io"
    ];
  };
}

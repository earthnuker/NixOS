{
  config,
  lib,
  ...
} @ inputs: let
  quadlet = config.virtualisation.quadlet;
  inherit (import ./lib.nix inputs) mkPod;
in {
  virtualisation.quadlet = mkPod "ghidra" {
    extraPodConfig = {
      publishPorts = [
        13100
        13101
        13102
      ];
    };
    services = {
      server = {
        image = "blacktop/ghidra:alpine";
        volumes = [
          "/mnt/data/ghidra:/srv/repositories"
        ];
        extraContainerArgs.entrypoint = "/entrypoint.sh server";
        environment = {
          GHIDRA_USERS = "admin earthnuker strongleong";
          GHIDRA_PUBLIC_HOSTNAME = "ghidra";
        };
      };
      tailscale = {
        image = "tailscale/tailscale:latest";
        volumes = [
          "/dev/net/tun:/dev/net/tun"
        ];
        extraContainerArgs = {
          addCapabilities = ["NET_ADMIN" "SYS_MODULE"];
          environmentFiles = [
            config.sops.secrets.ghidra_ts_env.path
          ];
        };

        environment = {
          TS_EXTRA_ARGS = "--advertise-tags=tag:ghidra";
          TS_STATE_DIR = "/var/lib/tailscale";
        };
      };
    };
  };
}

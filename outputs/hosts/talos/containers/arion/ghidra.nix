{config, ...} @ inputs: let
  inherit (import ./lib.nix) mkService;
in {
  services = {
    ghidra = mkService {
      image = "blacktop/ghidra:alpine";
      hostname = "ghidra-server";
      volumes = [
        "/mnt/data/ghidra:/srv/repositories"
      ];
      extraServiceArgs = {
        command = "server";
        network_mode = "service:tailscale";
      };
      environment = {
        GHIDRA_USERS = "admin earthnuker strongleong";
        GHIDRA_PUBLIC_HOSTNAME = "ghidra";
        GHIDRA_IP = "ghidra";
      };
    };
    tailscale = mkService {
      image = "tailscale/tailscale:latest";
      hostname = "ghidra";
      ports = [13100 13101 13102];
      extraServiceArgs = {
        capabilities = {
          NET_ADMIN = true;
          SYS_MODULE = true;
        };
        env_file = [
          config.sops.secrets.ghidra_ts_env.path
        ];
        devices = [
          "/dev/net/tun"
        ];
      };

      environment = {
        TS_EXTRA_ARGS = "--advertise-tags=tag:ghidra";
        TS_STATE_DIR = "/var/lib/tailscale";
      };
    };
  };
}

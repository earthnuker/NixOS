{config, ...}: rec {
  image = "tailscale/tailscale:latest";
  hostname = "ghidra";
  ports = [
    "13100:13100"
    "13101:13101"
    "13102:13102"
  ];
  volumes = [
    "/dev/net/tun:/dev/net/tun"
  ];
  capabilities = {
    NET_ADMIN = true;
    SYS_MODULE = true;
  };
  environment = {
    TS_EXTRA_ARGS = "--advertise-tags=tag:ghidra";
    TS_STATE_DIR = "/var/lib/tailscale";
  };
  environmentFiles = [
    config.sops.secrets.ghidra_ts_env.path
  ];
}

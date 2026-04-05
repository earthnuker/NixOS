{
  services.tailscale = {
    enable = true;
    # useRoutingFeatures = "both";
    # interfaceName = "userspace-networking";
    # authKeyFile = "/var/run/credentials/ts.auth";
    extraUpFlags = ["--ssh"];
  };
  systemd.services.tailscaled.after = ["network-online.target"];
}

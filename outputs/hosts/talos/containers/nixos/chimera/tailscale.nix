{
  services.tailscale = {
    enable = true;
    # useRoutingFeatures = "both";
    # interfaceName = "userspace-networking";
    # authKeyFile = "/var/run/credentials/ts.auth";
    extraUpFlags = ["--ssh"];
  };
}

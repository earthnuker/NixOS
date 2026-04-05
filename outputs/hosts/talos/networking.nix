{
  services.timesyncd.servers = [
    "0.nixos.pool.ntp.org"
    "1.nixos.pool.ntp.org"
    "2.nixos.pool.ntp.org"
    "3.nixos.pool.ntp.org"
  ];
  networking = {
    hostName = "talos";
    useNetworkd = true;
    interfaces = {};
    firewall = {
      enable = true;
      allowPing = true;
    };
  };
}

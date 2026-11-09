{lib, ...}: {
  services.coredns = {
    enable = true;
    config = lib.readFile ./Corefile;
  };
  # TODO: dnsmasqd
  services.resolved.enable = true;
}

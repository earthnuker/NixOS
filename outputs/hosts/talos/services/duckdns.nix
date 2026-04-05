{config, ...}: {
  sops.secrets.duckdns_token.restartUnits = [
    "duckdns.service"
  ];
  services.duckdns = {
    enable = false;
    domains = ["earthnuker"];
    tokenFile = config.sops.secrets.duckdns_token.path;
  };
}

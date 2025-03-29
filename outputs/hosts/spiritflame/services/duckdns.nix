{config, ...}: {
  services.duckdns = {
    enable = true;
    domains = ["earthnuker"];
    tokenFile = config.sops.secrets.duckdns_token.path;
  };
}

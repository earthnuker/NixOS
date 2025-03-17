{config, ...}: {
  services.duckdns = {
    enable = true;
    domains = ["earthnuker"];
    tokenFile = config.age.secrets.duckdns.path;
  };
}

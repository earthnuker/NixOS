{config, ...}: {
  services.searx = {
    enable = false;
    redisCreateLocally = true;
    environmentFile = config.sops.secrets.searxng_env.path;
    settings.server = {
      bind_address = "127.0.0.1";
      port = 8888;
    };
  };
}

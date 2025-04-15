{config, ...}: {
  services.nats = {
    enable = true;
    validateConfig = true;
    jetstream = true;
    serverName = config.networking.hostName;
    settings = {
      http_port = 8222;
    };
  };
}

{config, ...}: {
  sops.secrets.miniflux_creds = {
    mode = "0400";
    restartUnits = ["miniflux.service"];
  };
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux_creds.path;
    config.LISTEN_ADDR = "127.0.0.1:8752";
  };
}

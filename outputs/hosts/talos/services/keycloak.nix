{
  config,
  pkgs,
  ...
}: {
  services.keycloak = {
    enable = true;
    plugins = with pkgs.keycloak.plugins; [
      keycloak-discord
    ];
    settings = {
      hostname = "auth.${config.networking.fqdn}";
      proxy-address-forwarding = true;
      http-enabled = true;
      http-port = 21765;
      # proxy-headers = "xforwarded";
      # hostname-backchannel-dynamic = true;
      # hostname-strict = false;
    };
    database.passwordFile = config.sops.secrets.keycloak_db.path;
  };
}

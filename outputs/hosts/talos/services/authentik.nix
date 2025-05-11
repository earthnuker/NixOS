{config, ...}: {
  services.authentik = {
    enable = false;
    environmentFile = config.sops.secrets.authentik_env.path;
    settings = {
      disable_startup_analytics = true;
      avatars = "attributes.avatar,gravatar,initials";
      listen = {
        address = "127.0.0.1";
        http = 9000;
        https = 9443;
      };
    };
  };
}

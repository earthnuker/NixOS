{config, ...}: {
  sops.secrets.authentik_env = {};
  services.authentik = {
    enable = false;
    environmentFile = config.sops.secrets.authentik_env.path;
    createDatabase = true;
    settings = {
      disable_startup_analytics = true;
      avatars = "attributes.avatar,gravatar,initials";
      listen = {
        address = "127.0.0.1";
        http = 7000;
        https = 7443;
      };
    };
  };
}

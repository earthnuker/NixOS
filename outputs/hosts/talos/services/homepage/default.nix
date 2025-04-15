{config, ...} @ inputs: {
  services.homepage-dashboard = {
    services = import ./services.nix inputs;
    settings = import ./settings.nix inputs;
    widgets = import ./widgets.nix inputs;
    enable = true;
    environmentFile = config.sops.secrets.homepage_env.path;
    openFirewall = true;
    docker = {
      local = {
        host = "127.0.0.1";
        port = 2375;
      };
    };
  };
}

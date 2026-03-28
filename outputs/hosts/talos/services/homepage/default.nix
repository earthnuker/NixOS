{config, ...}: {
  sops.secrets.homepage_env = {};
  services.homepage-dashboard = {
    services = [
      {
        "System" = [
          {
            "Grafana" = {
              href = "http://monitoring.talos.lan/";
              widget = {
                type = "grafana";
                url = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
                username = "admin";
                password = "adminadmin";
              };
            };
          }
        ];
      }
    ];
    settings = {
      title = "${config.networking.hostName} Homepage";
    };
    widgets = [
      {
        resources = {
          disk = "/mnt/data";
          label = "Storage";
        };
      }
      {
        resources = {
          disk = "/";
          cpu = true;
          memory = true;
          label = "System";
        };
      }
    ];
    enable = true;
    environmentFiles = [config.sops.secrets.homepage_env.path];
    openFirewall = true;
    docker = {
      local = {
        host = "127.0.0.1";
        port = 2375;
      };
    };
  };
}

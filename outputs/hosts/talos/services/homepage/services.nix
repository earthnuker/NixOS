{config, ...}: [
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
]

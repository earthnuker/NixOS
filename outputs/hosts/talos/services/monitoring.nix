{config, ...}: {
  services = {
    grafana = {
      enable = true;
      settings = {
        server = {
          domain = "monitoring.${config.networking.hostName}.lan";
          root_url = "http://monitoring.${config.networking.hostName}.lan/";
        };
      };
    };
    prometheus = {
      enable = true;
      enableReload = true;
      exporters = {
        zfs.enable = true;
        smartctl.enable = true;
        # pihole.enable = true;
        # nats.enable = true;
        node = {
          enable = true;
          enabledCollectors = ["systemd"];
        };
      };
      scrapeConfigs = [
        {
          job_name = "talos";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
                "127.0.0.1:${toString config.services.prometheus.exporters.zfs.port}"
                "127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}"
              ];
            }
          ];
        }
      ];
    };
  };
}

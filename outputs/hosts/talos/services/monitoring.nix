{config, ...}: {
  systemd.tmpfiles.rules = [
    "Z /sys/devices/virtual/powercap - scaphandre-exporter scaphandre-exporter"
  ];
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
      listenAddress = "127.0.0.1";
      exporters = {
        zfs.enable = true;
        smartctl.enable = true;
        pihole = {
          enable = true;
          piholeHostname = "pi.hole";
          password = "hackme";
          port = 9617;
        };
        scaphandre = {
          enable = true;
          port = 9876;
          telemetryPath = "metrics";
        };
        # nats.enable = true;
        node = {
          enable = true;
          enabledCollectors = ["systemd" "rapl"];
        };
      };
      scrapeConfigs = [
        {
          job_name = "talos";
          fallback_scrape_protocol = "PrometheusText1.0.0";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
                "127.0.0.1:${toString config.services.prometheus.exporters.zfs.port}"
                "127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}"
                "127.0.0.1:${toString config.services.prometheus.exporters.scaphandre.port}"
                "127.0.0.1:${toString config.services.prometheus.exporters.pihole.port}"
              ];
            }
          ];
        }
      ];
    };
  };
}

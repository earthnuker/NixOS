{
  config,
  lib,
  ...
}: let
  mkScrapeConfig = name: port: {
    job_name = "${name}@${config.networking.hostName}";
    fallback_scrape_protocol = "PrometheusText1.0.0";
    static_configs = [
      {
        targets = [
          "127.0.0.1:${toString port}"
        ];
      }
    ];
  };
in {
  imports = [
    # ./vodafone-station-exporter
    ./tapo-exporter
  ];
  systemd.tmpfiles.rules = lib.mkIf config.services.prometheus.exporters.scaphandre.enable [
    "Z /sys/devices/virtual/powercap - scaphandre-exporter scaphandre-exporter"
  ];
  services = {
    cadvisor = {
      enable = false;
      port = 9877;
    };
    grafana = {
      enable = true;
      settings = {
        analytics = {
          feedback_links_enabled = false;
          reporting_enabled = false;
        };
        log.level = "warn";
        security = {
          cookie_secure = false;
          content_security_policy = true;
          strict_transport_security = true;
        };
        server = {
          enable_gzip = true;
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
        blackbox = {
          enable = true;
          configFile = ./blackbox.yml;
        };
        pihole = {
          enable = false;
          piholeHostname = "dietpi.lan";
          password = "hackme";
          port = 9617;
        };
        scaphandre = {
          enable = false;
          port = 9876;
          telemetryPath = "metrics";
        };
        # nats.enable = true;
        node = {
          enable = true;
          enabledCollectors = [
            "systemd"
            "rapl"
          ];
        };
      };
      globalConfig.external_labels = {
        host = "${config.networking.hostName}";
      };
      scrapeConfigs = [
        (mkScrapeConfig "node" config.services.prometheus.exporters.node.port)
        (mkScrapeConfig "zfs" config.services.prometheus.exporters.zfs.port)
        (mkScrapeConfig "smartctl" config.services.prometheus.exporters.smartctl.port)
        # (mkScrapeConfig "scaphandre" config.services.prometheus.exporters.scaphandre.port)
        (mkScrapeConfig "pihole" config.services.prometheus.exporters.pihole.port)
        (mkScrapeConfig "blackbox" config.services.prometheus.exporters.blackbox.port)
        (mkScrapeConfig "tapo" 9105)
        # (mkScrapeConfig "vodafone-station" 9420)
        # (mkScrapeConfig "cadvisor" config.services.cadvisor.port)
      ];
    };
  };
}

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
  mkProbeConfig = name: module: targets: {
    job_name = "blackbox-${name}@${config.networking.hostName}";
    metrics_path = "/probe";
    fallback_scrape_protocol = "PrometheusText1.0.0";
    params.module = [module];
    static_configs = [{inherit targets;}];
    relabel_configs = [
      # 1. Turn the target list entry into the ?target= query param
      {
        source_labels = ["__address__"];
        target_label = "__param_target";
      }
      # 2. Keep it readable in metrics as the `instance` label
      {
        source_labels = ["__param_target"];
        target_label = "instance";
      }
      # 3. Redirect the actual scrape to the local exporter
      {
        target_label = "__address__";
        replacement = "127.0.0.1:${toString config.services.prometheus.exporters.blackbox.port}";
      }
    ];
  };
in {
  imports = [
    # ./vodafone-station-exporter
    ./tapo-exporter
  ];
  sops.secrets.grafana_key = {};

  services = {
    cadvisor = {
      enable = false;
      port = 9877;
    };
    grafana = {
      enable = true;
      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "VictoriaMetrics";
            type = "prometheus";
            url = "http://${config.services.victoriametrics.listenAddress}";
            isDefault = true;
            editable = false;
          }
          {
            name = "Loki";
            type = "loki";
            url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
            editable = false;
          }
        ];
      };
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
          secret_key = "$__file(${config.sops.secrets.grafana_key.path})";
        };
        server = {
          enable_gzip = true;
          domain = "monitoring.${config.networking.hostName}.lan";
          root_url = "http://monitoring.${config.networking.hostName}.lan/";
        };
      };
    };
    victoriametrics = {
      enable = true;
      listenAddress = "127.0.0.1:8428";
      retentionPeriod = "5y"; # suffixes s/h/d/w/y; bare number = months, min 24h
      extraOptions = ["-dedup.minScrapeInterval=15s"];
    };
    prometheus = {
      enable = true;
      enableReload = true;
      listenAddress = "127.0.0.1";
      extraFlags = ["--web.enable-admin-api"];
      remoteWrite = [
        {
          url = "http://127.0.0.1:8428/api/v1/write";
        }
      ];
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
        # nats.enable = true;
        node = {
          enable = true;
          enabledCollectors = [
            "systemd"
            "rapl"
          ];
        };
        speedtest = {
          enable = true;
        };
      };
      alertmanagers = [{static_configs = [{targets = ["127.0.0.1:9093"];}];}];
      ruleFiles = [
        ./alerting.rules.yml
      ];
      globalConfig.external_labels = {
        host = "${config.networking.hostName}";
      };
      scrapeConfigs = [
        (mkScrapeConfig "node" config.services.prometheus.exporters.node.port)
        (mkScrapeConfig "zfs" config.services.prometheus.exporters.zfs.port)
        (mkScrapeConfig "smartctl" config.services.prometheus.exporters.smartctl.port)
        # (mkScrapeConfig "pihole" config.services.prometheus.exporters.pihole.port)
        (mkScrapeConfig "blackbox" config.services.prometheus.exporters.blackbox.port)
        (mkScrapeConfig "victoriametrics" 8428)
        (mkScrapeConfig "tapo" 9105)
        (mkScrapeConfig "caddy" 2019)
        (
          (mkScrapeConfig "speedtest" config.services.prometheus.exporters.speedtest.port)
          // {
            scrape_interval = "1h";
            scrape_timeout = "60s";
          }
        )
        (mkProbeConfig "http" "http_2xx" [
          "http://monitoring.${config.networking.hostName}.lan" # grafana vhost
          "http://192.168.0.1"
          "http://192.168.0.2"
          "http://google.com"
          "http://heise.de"
        ])
        (mkProbeConfig "https" "https_2xx" [
          "https://google.com"
          "https://heise.de"
          "https://earthnuker.xyz"
        ])
        (mkProbeConfig "icmp" "icmp" [
          "1.1.1.1"
          "9.9.9.9"
          "8.8.8.8"
          "192.168.0.1"
          "192.168.0.2"
        ])
        (mkProbeConfig "dns" "dns_a" [
          "1.1.1.1:53"
          "192.168.0.2:53"
        ])
      ];
    };
    # --- Loki Configuration ---
    loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server = {
          http_listen_port = 3100;
          http_listen_address = "127.0.0.1";
        };
        common = {
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "inmemory";
          };
          replication_factor = 1;
          path_prefix = "/var/lib/loki";
        };
        ruler = {
          storage = {
            type = "local";
            local.directory = "/etc/loki/rules"; # base path
          };
          rule_path = "/var/lib/loki/rules-temp"; # scratch space for the ruler
          alertmanager_url = "http://127.0.0.1:9093";
          enable_alertmanager_v2 = true;
        };
        schema_config.configs = [
          {
            from = "2024-12-01";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
          {
            from = "2026-11-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
        storage_config = {
          filesystem.directory = "/var/lib/loki/chunks";
        };
        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
          allow_structured_metadata = false;
          retention_period = "365d"; # pick your horizon
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          compaction_interval = "10m";
          retention_enabled = true;
          retention_delete_delay = "2h";
          delete_request_store = "filesystem"; # valid value for your filesystem backend
        };
      };
    };

    alloy = {
      enable = true;
      extraFlags = [
        "--server.http.listen-addr=127.0.0.1:9080"
        "--disable-reporting"
      ];
    };
  };
  systemd.services.alloy.serviceConfig.SupplementaryGroups = lib.mkAfter [
    "systemd-journal"
    "caddy"
    "podman"
  ];
  environment.etc."loki/rules/fake/systemd.yml".text = lib.readFile ./loki.rules.yml;
  environment.etc."alloy/config.alloy".text = ''
    // Relabel rules to extract useful labels from journal metadata.
    loki.relabel "journal" {
        forward_to = []

        rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
        }

        rule {
            source_labels = ["__journal__hostname"]
            target_label  = "hostname"
        }
    }

    loki.source.journal "read" {
        forward_to    = [loki.write.local.receiver]
        relabel_rules = loki.relabel.journal.rules
        max_age       = "12h"

        labels = {
            job  = "systemd-journal",
            host = "${config.networking.hostName}",
        }
    }

    // Caddy access logs written to files.
    loki.source.file "caddy" {
        targets = [
          {
              __path__ = "/var/log/caddy/*.log",
              job  = "caddy",
              host = "${config.networking.hostName}",
          },
        ]

       file_match {
         enabled = true
       }

       forward_to = [loki.write.local.receiver]
    }

    // Discover containers through Podman's Docker-compatible API.
    discovery.docker "podman" {
        host = "unix:///run/podman/podman.sock"
    }

    // Extract useful labels from container metadata.
    discovery.relabel "podman_logs" {
        targets = []

        rule {
            source_labels = ["__meta_docker_container_name"]
            regex         = "/(.*)"
            target_label  = "container"
        }
    }

    // Collect container stdout/stderr.
    loki.source.docker "podman" {
        host          = "unix:///run/podman/podman.sock"
        targets       = discovery.docker.podman.targets
        relabel_rules = discovery.relabel.podman_logs.rules

        labels = {
            job  = "podman",
            host = "${config.networking.hostName}",
        }

        forward_to = [loki.write.local.receiver]
    }

    // Send logs to the local Loki instance.
    loki.write "local" {
        endpoint {
            url = "http://127.0.0.1:3100/loki/api/v1/push"
        }
    }
  '';
}

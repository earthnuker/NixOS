{
  config,
  lib,
  ...
} @ inputs: let
  quadlet = config.virtualisation.quadlet;
  userId = 1000;
  groupId = 1000;
  exposedPorts = {
    qbittorrent = [8080 5000];
    flaresolverr = [8191];
    bazarr = [6767];
    prowlarr = [9696];
    radarr = [7878];
    sonarr = [8989];
    lidarr = [8686 6595];
  };
  containerVolumes = {
    config = "/mnt/data/config";
    media = "/mnt/data/media";
    downloads = "/mnt/data/downloads";
  };
  globalEnv = {
    TZ = "Europe/Berlin";
    PUID = toString userId;
    PGID = toString groupId;
  };
  toLocalPort = port: "127.0.0.1:${toString port}:${toString port}";
  mkService = {
    image,
    name,
    autoStart ? true,
    ports ? [],
    volumes ? [],
    env ? {},
    configDir ? "/config",
    pod ? null,
    extraContainerArgs ? {},
    extraServiceArgs ? {},
  }: {
    inherit autoStart;
    containerConfig =
      {
        # Defaults
        inherit image name;
        pod = lib.optionalString (pod != null) quadlet.pods.${pod}.ref;
        volumes =
          [
            "${containerVolumes.config}/${name}:${configDir}"
          ]
          ++ volumes;
        environments = globalEnv // env;
        publishPorts = map toLocalPort ports;
        startWithPod = true;
      }
      // extraContainerArgs; # Overrides
    serviceConfig =
      {
        # Defaults
        RestartSec = "10";
        Restart = "always";
      }
      // extraServiceArgs; # Overrides
  };

  mkPod = pod_name: {
    services,
    extraPodConfig ? {},
  }: let
    publishPorts = map toLocalPort (lib.unique (lib.concatMap (svc: svc.ports or []) (lib.attrValues services)));
    mkContainer = name: value:
      mkService ((lib.removeAttrs value ["ports"])
        // {
          pod = pod_name;
          name = name;
        });
  in {
    containers = lib.mapAttrs mkContainer services;
    pods."${pod_name}" = {
      podConfig = {inherit publishPorts;} // extraPodConfig;
    };
  };
in (mkPod "tvstack" {
  services = {
    sonarr = {
      image = "hotio/sonarr:release";
      volumes = [
        "${containerVolumes.media}:/media"
        "${containerVolumes.downloads}:/downloads"
      ];
      ports = [8989];
    };
    radarr = {
      image = "hotio/radarr:release";
      volumes = [
        "${containerVolumes.media}:/media"
        "${containerVolumes.downloads}:/downloads"
      ];
      ports = [7878];
    };
    lidarr = rec {
      image = "youegraillot/lidarr-on-steroids";
      volumes = [
        "${containerVolumes.media}/music:/music"
        "${containerVolumes.config}/lidarr/deemix:/config_deemix"
        "${containerVolumes.downloads}:/downloads"
      ];
      ports = [8686 6595];
    };
    prowlarr = {
      image = "hotio/prowlarr:release";
      ports = [9696];
    };
    bazarr = {
      image = "hotio/bazarr:release";
      ports = [6767];
      volumes = [
        "${containerVolumes.media}:/media"
      ];
    };
    flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr";
      ports = [8191];
    };
    qbittorrent = {
      image = "hotio/qbittorrent:legacy";
      ports = [8080 5000];
      extraContainerArgs = {
        addCapabilities = ["NET_ADMIN"];
        sysctl = {
          "net.ipv4.conf.all.src_valid_mark" = "1";
          "net.ipv6.conf.all.disable_ipv6" = "1";
        };
        devices = [
          "/dev/net/tun"
        ];
        environmentFiles = [config.sops.secrets.vpn_env.path];
      };
      volumes = [
        "${containerVolumes.downloads}:/app/qBittorrent/downloads"
      ];
    };
  };
})

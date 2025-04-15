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
        inherit image pod name;
        volumes =
          [
            "${containerVolumes.config}/${name}:${configDir}"
          ]
          ++ volumes;
        environments = globalEnv // env;
        publishPorts = map toLocalPort ports;
        startWithPod = true;
      }
      // extraContainerArgs;
    serviceConfig =
      {
        RestartSec = "10";
        Restart = "always";
      }
      // extraServiceArgs;
  };
in rec {
  containers = {
    sonarr = mkService {
      image = "hotio/sonarr:release";
      name = "sonarr";
      pod = quadlet.pods.tvstack.ref;
      volumes = [
        "${containerVolumes.media}:/media"
        "${containerVolumes.downloads}:/downloads"
      ];
      # ports = [8989];
    };
    radarr = mkService {
      image = "hotio/radarr:release";
      name = "radarr";
      pod = quadlet.pods.tvstack.ref;
      volumes = [
        "${containerVolumes.media}:/media"
        "${containerVolumes.downloads}:/downloads"
      ];
      # ports = [7878];
    };
    lidarr = mkService rec {
      image = "youegraillot/lidarr-on-steroids";
      name = "lidarr";
      pod = quadlet.pods.tvstack.ref;
      volumes = [
        "${containerVolumes.media}/music:/music"
        "${containerVolumes.config}/${name}/deemix:/config_deemix"
        "${containerVolumes.downloads}:/downloads"
      ];
      # ports = [8686 6595];
    };
    prowlarr = mkService {
      image = "hotio/prowlarr:release";
      name = "prowlarr";
      pod = quadlet.pods.tvstack.ref;
      # ports = [9696];
    };
    bazarr = mkService {
      image = "hotio/bazarr:release";
      name = "bazarr";
      pod = quadlet.pods.tvstack.ref;
      # ports = [6767];
      volumes = [
        "${containerVolumes.media}:/media"
      ];
    };
    flaresolverr = mkService {
      image = "ghcr.io/flaresolverr/flaresolverr";
      name = "flaresolverr";
      pod = quadlet.pods.tvstack.ref;
      # ports = [8191];
    };
    qbittorrent = mkService {
      image = "hotio/qbittorrent:release";
      name = "qbittorrent";
      pod = quadlet.pods.tvstack.ref;
      # ports = [8080 5000];
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
  pods = {
    tvstack = {
      podConfig.publishPorts = map toLocalPort (builtins.concatLists (builtins.attrValues exposedPorts));
    };
  };
}

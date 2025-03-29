{config, ...} @ inputs: let
  userId = 1000;
  groupId = 1000;
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
  mkService = {
    image,
    hostname,
    ports ? [],
    volumes ? [],
    environment ? {},
    configDir ? "/config",
    extraArgs ? {},
    extraServiceArgs ? {},
  }:
    {
      service =
        {
          inherit image hostname ports;
          volumes =
            [
              "${containerVolumes.config}/${hostname}:${configDir}"
            ]
            ++ volumes;
          environment = globalEnv // environment;
        }
        // extraServiceArgs;

      out = {
        service = {
          pull_policy = "always";
        };
      };
    }
    // extraArgs;
in {
  services = {
    sonarr = mkService {
      image = "hotio/sonarr:release";
      hostname = "sonarr";
      ports = [
        "8989:8989"
      ];
      volumes = [
        "/mnt/data/media:/media"
      ];
    };
    radarr = mkService {
      image = "hotio/radarr:release";
      hostname = "radarr";
      ports = [
        "7878:7878"
      ];
      volumes = [
        "${containerVolumes.media}:/media"
      ];
    };
    prowlarr = mkService {
      image = "hotio/prowlarr:release";
      hostname = "prowlarr";
      ports = [
        "9696:9696"
      ];
      volumes = [
        "${containerVolumes.media}:/media"
      ];
    };
    bazarr = mkService {
      image = "hotio/bazarr:release";
      hostname = "bazarr";
      ports = [
        "6767:6767"
      ];
      volumes = [
        "${containerVolumes.media}:/media"
      ];
    };
    qbittorrent = mkService {
      image = "hotio/qbittorrent:release";
      hostname = "qbittorrent";
      ports = [
        "8080:8080"
        "5000:5000"
      ];
      extraServiceArgs = {
        env_file = [config.sops.secrets.vpn_env.path];
        capabilities = {NET_ADMIN = true;};
        sysctls = {
          "net.ipv4.conf.all.src_valid_mark" = 1;
          "net.ipv6.conf.all.disable_ipv6" = 1;
        };
      };
      volumes = [
        "${containerVolumes.downloads}:/downloads"
        "/dev/net/tun:/dev/net/tun"
      ];
    };
  };
}

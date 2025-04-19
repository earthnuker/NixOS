{config, ...} @ inputs: let
  inherit (import ./lib.nix) mkService containerVolumes;
in {
  services = {
    sonarr = mkService {
      image = "hotio/sonarr:release";
      hostname = "sonarr";
      ports = [8989];
      volumes = [
        "${containerVolumes.media}:/media"
        "${containerVolumes.downloads}:/downloads"
      ];
    };
    radarr = mkService {
      image = "hotio/radarr:release";
      hostname = "radarr";
      ports = [7878];
      volumes = [
        "${containerVolumes.media}:/media"
        "${containerVolumes.downloads}:/downloads"
      ];
    };
    prowlarr = mkService {
      image = "hotio/prowlarr:release";
      hostname = "prowlarr";
      ports = [9696];
    };
    bazarr = mkService {
      image = "hotio/bazarr:release";
      hostname = "bazarr";
      ports = [6767];
      volumes = [
        "${containerVolumes.media}:/media"
      ];
    };
    flaresolverr = mkService {
      image = "ghcr.io/flaresolverr/flaresolverr";
      hostname = "flaresolverr";
      ports = [8191];
    };
    qbittorrent = mkService {
      image = "hotio/qbittorrent:release";
      hostname = "qbittorrent";
      ports = [8080 5000];
      extraServiceArgs = {
        env_file = [config.sops.secrets.vpn_env.path];
        capabilities = {NET_ADMIN = true;};
        sysctls = {
          "net.ipv4.conf.all.src_valid_mark" = 1;
          "net.ipv6.conf.all.disable_ipv6" = 1;
        };
      };
      volumes = [
        "${containerVolumes.downloads}:/app/qBittorrent/downloads"
        "/dev/net/tun:/dev/net/tun"
      ];
    };
  };
}

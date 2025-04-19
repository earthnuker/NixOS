{
  config,
  lib,
  ...
} @ inputs: let
  quadlet = config.virtualisation.quadlet;
  inherit (import ./lib.nix inputs) mkPod containerVolumes;
in {
  virtualisation.quadlet = mkPod "tvstack" {
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
  };
}

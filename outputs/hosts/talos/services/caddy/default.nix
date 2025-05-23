{
  config,
  lib,
  pkgs,
  ...
}: let
  tailnet = "possum-gila.ts.net";
  hostname = config.networking.hostName;
  localTld = "lan";
  tailscaleTld = "ts";
  revProxy = port: "reverse_proxy 127.0.0.1:${toString port}";
  mkCaddy = {
    apps ? {},
    suffixes ? [localTld tailscaleTld],
    extraConfigPre ? {},
    extraConfigPost ? {},
    extraHosts ? {},
    commonConfig ? "",
  }: let
    # TODO: auth option
    mkHost = name: {
      "${lib.concatStringsSep ", " (map (tld: "${name}.${hostname}.${tld}:80") suffixes)}" = {
        extraConfig = lib.concatStringsSep "\n" [
          commonConfig
          (extraConfigPre.${name} or "")
          "reverse_proxy http://127.0.0.1:${toString apps.${name}}"
          (extraConfigPost.${name} or "")
        ];
      };
    };
  in
    (lib.mergeAttrsList (map mkHost (builtins.attrNames apps)))
    // extraHosts;
  glowingBearCaddy = ''
    # Proxy WebSocket connections at /weechat to WeeChat relay on port 9001
    reverse_proxy /weechat 127.0.0.1:9001 {
      flush_interval -1
    }
    root * ${pkgs.glowing-bear}
    file_server
  '';
  weechatCaddy = ''
    reverse_proxy 127.0.0.1:9000 {
      flush_interval -1
    }
  '';
in {
  services.caddy = {
    enable = true;
    adapter = "caddyfile";
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/greenpau/caddy-security@v1.1.31"
        "go.akpain.net/caddy-tailscale-auth@v0.1.7"
      ];
      hash = "sha256-OFqOcNbZ7w5mJke389EFfTTLaAzZl+8VLPu/6nr57tw=";
    };
    environmentFile = config.sops.secrets.caddy_env.path;
    logFormat = lib.mkForce ''
      format console
      level DEBUG
    '';
    globalConfig = lib.readFile ./global_config;
    extraConfig = lib.readFile ./extra_config;
    virtualHosts = mkCaddy {
      apps =
        {
          search = config.services.searx.settings.server.port;
          prometheus = config.services.prometheus.port;
          photos = config.services.immich.port;
          monitoring = config.services.grafana.settings.server.http_port;
          cadvisor = config.services.cadvisor.port;
          code = config.services.forgejo.settings.server.HTTP_PORT;
          dc = config.services.lldap.settings.http_port;
          lounge = config.services.thelounge.port;
          glance = config.services.glance.settings.server.port;
        }
        // (lib.optionalAttrs config.hive.services.tvstack.enable {
          torrent = 8080;
          sonarr = 8989;
          radarr = 7878;
          bazarr = 6767;
          prowlarr = 9696;
        });
      extraHosts = {
        "${hostname}.${tailnet}:80".extraConfig = ''
          respond "Hello from {hostport} to {header.X-Forwarded-For}"
        '';
        "auth-test.${hostname}.${localTld}:80, auth-test.${hostname}.${tailscaleTld}:80".extraConfig = ''
          import auth talos user {
            reverse_proxy 127.0.0.1:31337
          }
        '';
        "${hostname}.${tailscaleTld}:80, ${hostname}.${localTld}:80".extraConfig =
          revProxy config.services.homepage-dashboard.listenPort;
        "irc.${hostname}.${tailscaleTld}:80, irc.${hostname}.${localTld}:80".extraConfig = glowingBearCaddy;
        "wc.${hostname}.${tailscaleTld}:80, wc.${hostname}.${localTld}:80".extraConfig = weechatCaddy;
      };
    };
  };
}

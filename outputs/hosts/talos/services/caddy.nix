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
  mkCaddy = {
    apps ? {},
    suffixes ? [localTld tailscaleTld],
    extraConfig ? {},
    extraHosts ? {},
    commonConfig ? "",
  }: let
    mkHost = suffix: name: {
      name = "${name}.${hostname}.${suffix}:80";
      value = {
        extraConfig =
          commonConfig
          + ''reverse_proxy 127.0.0.1:${toString apps.${name}}''
          + "\n"
          + (extraConfig.${name} or "");
      };
    };
  in
    (builtins.listToAttrs (
      lib.concatMap (
        suffix:
          map (name: mkHost suffix name) (builtins.attrNames apps)
      )
      suffixes
    ))
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
    # Proxy WebSocket connections at /weechat to WeeChat relay on port 9001
    reverse_proxy 127.0.0.1:9000 {
      flush_interval -1
    }
  '';
in {
  services.caddy = {
    enable = true;
    adapter = "caddyfile";
    logFormat = lib.mkForce ''
      format console
      level INFO
    '';
    globalConfig = ''
      auto_https off
    '';
    virtualHosts = mkCaddy rec {
      apps =
        {
          search = config.services.searx.settings.server.port;
          prometheus = config.services.prometheus.port;
          photos = config.services.immich.port;
          monitoring = config.services.grafana.settings.server.http_port;
          auth = config.services.authentik.settings.listen.http;
          cadvisor = config.services.cadvisor.port;
          code = config.services.forgejo.settings.server.HTTP_PORT;
          dc = config.services.lldap.settings.http_port;
          lounge = config.services.thelounge.port;
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
        "${hostname}.${localTld}:80".extraConfig = ''
          reverse_proxy 127.0.0.1:${toString config.services.homepage-dashboard.listenPort}
        '';
        "${hostname}.${tailscaleTld}:80".extraConfig = ''
          reverse_proxy 127.0.0.1:${toString config.services.homepage-dashboard.listenPort}
        '';
        "irc.${hostname}.${tailscaleTld}:80".extraConfig = glowingBearCaddy;
        "irc.${hostname}.${localTld}:80".extraConfig = glowingBearCaddy;
        "wc.${hostname}.${tailscaleTld}:80".extraConfig = weechatCaddy;
        "wc.${hostname}.${localTld}:80".extraConfig = weechatCaddy;
      };
    };
  };
}

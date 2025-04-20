{
  config,
  lib,
  ...
}: let
  tailnet = "possum-gila.ts.net";
  hostname = config.networking.hostName;
  localTld = "lan";
  tailscaleTld = "ts";
  localProxy = port: {};
  mkCaddy = {
    apps ? {},
    extraConfig ? {},
    extraHosts ? {},
    commonConfig ? "",
  }:
    builtins.listToAttrs (
      map (name: {
        name = "${name}.${hostname}.${localTld}:80";
        value = {
          extraConfig =
            commonConfig
            + ''reverse_proxy 127.0.0.1:${toString apps.${name}}''
            + "\n"
            + (extraConfig.${name} or "");
        };
      }) (builtins.attrNames apps)
    )
    // builtins.listToAttrs (
      map (name: {
        name = "${name}.${hostname}.${tailscaleTld}:80";
        value = {
          extraConfig =
            commonConfig
            + ''reverse_proxy 127.0.0.1:${toString apps.${name}}''
            + "\n"
            + (extraConfig.${name} or "");
        };
      }) (builtins.attrNames apps)
    )
    // extraHosts;
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
        }
        // (lib.optionalAttrs (lib.hasAttr "tvstack" config.virtualisation.arion.projects) {
          torrent = 8080;
          sonarr = 8989;
          radarr = 7878;
          bazarr = 6767;
          prowlarr = 9696;
        });
      extraHosts = {
        "${hostname}.${localTld}:80".extraConfig = ''
          reverse_proxy 127.0.0.1:${toString config.services.homepage-dashboard.listenPort}
        '';
        "${hostname}.${tailscaleTld}:80".extraConfig = ''
          reverse_proxy 127.0.0.1:${toString config.services.homepage-dashboard.listenPort}
        '';
        "${hostname}.${tailnet}:80".extraConfig = ''
          respond "Hello from {hostport} to {header.X-Forwarded-For}"
        '';
      };
    };
  };
}

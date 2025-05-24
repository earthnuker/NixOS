{
  config,
  lib,
  pkgs,
  ...
}: let
  hostname = config.networking.hostName;
  tld = {
    ts = {
      local = "ts";
      funnel = "possum-gila.ts.net";
    };
    local = "lan";
  };
  revProxy = port: "reverse_proxy 127.0.0.1:${toString port}";
  mkCaddy = {
    apps ? {},
    suffixes ? [
      tld.ts.local
      tld.local
    ],
    extraConfigPre ? {},
    extraConfigPost ? {},
    extraHosts ? {},
    commonConfig ? "",
  }: let
    mkAuth = {
      group,
      inner,
    }: "import auth talos ${group} {\n ${inner} \n}";
    mkHost = name: let
      app_info = apps.${name};
      inner = lib.concatStringsSep "\n" [
        commonConfig
        (extraConfigPre.${name} or "")
        "reverse_proxy http://127.0.0.1:${toString app_info.port}"
        (extraConfigPost.${name} or "")
      ];
      group = app_info.auth or null;
    in {
      "${lib.concatStringsSep ", " (map (tld: "${name}.${hostname}.${tld}:80") suffixes)}" = {
        extraConfig =
          if group != null
          then mkAuth {inherit inner group;}
          else inner;
      };
    };
  in
    (lib.mergeAttrsList (map mkHost (builtins.attrNames apps))) // extraHosts;
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
          search = {inherit (config.services.searx.settings.server) port;};
          prometheus = {inherit (config.services.prometheus) port;};
          photos = {inherit (config.services.immich) port;};
          monitoring = {port = config.services.grafana.settings.server.http_port;};
          cadvisor = {inherit (config.services.cadvisor) port;};
          code = {port = config.services.forgejo.settings.server.HTTP_PORT;};
          dc = {port = config.services.lldap.settings.http_port;};
          lounge = {inherit (config.services.thelounge) port;};
          glance = {inherit (config.services.glance.settings.server) port;};
        }
        // (lib.optionalAttrs config.hive.services.tvstack.enable {
          torrent = {port = 8080;};
          sonarr = {port = 8989;};
          radarr = {port = 7878;};
          bazarr = {port = 6767;};
          prowlarr = {port = 9696;};
        });
      extraHosts = {
        "${hostname}.${tld.ts.funnel}:80".extraConfig = ''
          respond "Hello from {hostport} to {header.X-Forwarded-For}"
        '';
        "auth-test.${hostname}.${tld.local}:80, auth-test.${hostname}.${tld.ts.local}:80".extraConfig = ''
          import auth talos user {
            ${revProxy 31337}
          }
        '';
        "*.proxy.${hostname}.${tld.local}:80, *.proxy.${hostname}.${tld.ts.local}:80".extraConfig = ''
          @hostnames header_regexp host Host ([0-9]+)\..*
          handle @hostnames {
            reverse_proxy 127.0.0.1:{http.regexp.host.1}
          }
        '';
        "${hostname}.${tld.ts.local}:80, ${hostname}.${tld.local}:80".extraConfig =
          revProxy config.services.homepage-dashboard.listenPort;
        "irc.${hostname}.${tld.ts.local}:80, irc.${hostname}.${tld.local}:80".extraConfig =
          glowingBearCaddy;
        "wc.${hostname}.${tld.ts.local}:80, wc.${hostname}.${tld.local}:80".extraConfig = weechatCaddy;
      };
    };
  };
}

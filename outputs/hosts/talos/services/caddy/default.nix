{
  config,
  lib,
  pkgs,
  ...
}: let
  hostname = config.networking.hostName;
  tvstack = config.containers.tvstack or {};
  tvstack_config = tvstack.config.services or {};
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
    # service ? null,
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
      attrPath = [(app_info.service or "#")] ++ (lib.splitString "." (app_info.attr or "port"));
      port = lib.attrByPath attrPath (app_info.port or (-1)) config.services;
      host = app_info.host or "127.0.0.1";
      inner = lib.concatStringsSep "\n" [
        commonConfig
        (extraConfigPre.${name} or "")
        "reverse_proxy http://${host}:${toString port}"
        (extraConfigPost.${name} or "")
      ];
      group = app_info.auth or null;
    in
      assert lib.assertMsg (port != -1) "invalid port for ${name} at ${lib.concatStringsSep "." attrPath}"; {
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
        "github.com/tailscale/caddy-tailscale@v0.0.0-20250508175905-642f61fea3cc"
        "github.com/greenpau/caddy-security@v1.1.31"
        #"go.akpain.net/caddy-tailscale-auth@v0.1.7"
        "github.com/enum-gg/caddy-discord@v1.2.0"
      ];
      hash = "sha256-EXZp3I0MGHdgRAcuG1ooscACs+fA6Vl7KTdsRsiN/pU=";
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
          search = {
            service = "searx";
            attr = "settings.server.port";
          };
          baby = {
            port = 8234;
          };
          notes = {
            port = 5230;
          };
          prometheus = {service = "prometheus";};
          photos = {service = "immich";};
          monitoring = {
            service = "grafana";
            attr = "settings.server.http_port";
          };
          cadvisor = {service = "cadvisor";};
          code = {
            service = "forgejo";
            attr = "settings.server.HTTP_PORT";
          };
          # files = {
          #   service = "copyparty";
          #   attr = "p";
          # };
          dc = {
            service = "lldap";
            attr = "settings.http_port";
          };
          lounge = {service = "thelounge";};
          tty = {service = "ttyd";};
          glance = {
            service = "glance";
            attr = "settings.server.port";
          };
          wiki = {service = "gollum";};
          docs = {service = "paperless";};
          # yt = {service = "pinchflat";};
          podcasts = {service = "audiobookshelf";};
        }
        // (lib.optionalAttrs (tvstack != {}) {
          torrent = {
            port = 5123;
            host = tvstack.hostAddress;
          };
          sonarr = {
            inherit (tvstack_config.sonarr.settings.server) port;
          };
          radarr = {
            inherit (tvstack_config.radarr.settings.server) port;
          };
          lidarr = {
            inherit (tvstack_config.lidarr.settings.server) port;
          };
          bazarr = {
            port = tvstack_config.bazarr.listenPort;
          };
          prowlarr = {
            inherit (tvstack_config.prowlarr.settings.server) port;
          };
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
            import auth talos user {
              reverse_proxy 127.0.0.1:{http.regexp.host.1}
            }
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

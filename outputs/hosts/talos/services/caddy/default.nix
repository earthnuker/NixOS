{
  config,
  lib,
  pkgs,
  ...
}: let
  hostname = config.networking.hostName;
  tvstack = config.containers.tvstack or {};
  tvstack_svc = tvstack.config.services or {};
  tld = {
    ts = {
      local = "ts";
      funnel = "possum-gila.ts.net";
    };
    public = "earthnuker.xyz";
    duckdns = "${builtins.elemAt config.services.duckdns.domains 0}.duckdns.org";
    local = "lan";
  };
  mkHostnames = {
    name ? "",
    suffixes ? [
      tld.ts.local
      tld.local
    ],
    ports ? [80],
  }:
    lib.concatStringsSep ", " (map (
        tld:
          lib.concatStringsSep ", " (map (port: "${name}.${hostname}.${tld}:${toString port}") ports)
      )
      suffixes);
  mkCaddy = {
    apps ? {},
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
      proto = app_info.proto or "http";
      portVal = lib.attrByPath attrPath (app_info.port or (-1)) config.services;
      # A service attr may resolve to a string like "127.0.0.1:8080"; split off port/host.
      port =
        if builtins.isString portVal && lib.hasInfix ":" portVal
        then lib.toInt (lib.last (lib.splitString ":" portVal))
        else portVal;
      host =
        app_info.host or (
          if builtins.isString portVal && lib.hasInfix ":" portVal
          then let
            h = lib.head (lib.splitString ":" portVal);
          in
            if h == ""
            then "127.0.0.1"
            else h
          else "127.0.0.1"
        );
      inner = lib.concatStringsSep "\n" [
        commonConfig
        (extraConfigPre.${name} or "")
        "reverse_proxy ${proto}://${host}:${toString port}"
        (extraConfigPost.${name} or "")
      ];
      group = app_info.auth or null;
    in
      assert lib.assertMsg (
        port != -1
      ) "invalid port for ${name} at ${lib.concatStringsSep "." attrPath}: ${toString portVal}"; {
        "${mkHostnames {inherit name;}}" = {
          extraConfig =
            if group != null
            then mkAuth {inherit inner group;}
            else inner;
        };
      };
  in
    (lib.mergeAttrsList (map mkHost (builtins.attrNames apps))) // extraHosts;

  # `container "babybuddy"`      -> babybuddy.dns.podman:80
  # `container "babybuddy:8000"` -> babybuddy.dns.podman:8000
  container = spec: let
    parts = lib.splitString ":" spec;
    name = lib.head parts;
    port =
      if lib.length parts > 1
      then lib.toInt (lib.elemAt parts 1)
      else 80;
  in {
    host = "${name}.dns.podman";
    inherit port;
  };

  # `service "searx:settings.server.port"` -> config.services.searx.settings.server.port
  # `service "prometheus"`                 -> config.services.prometheus.port
  service = spec: let
    parts = lib.splitString ":" spec;
    name = lib.head parts;
    attr = lib.concatStringsSep ":" (lib.tail parts);
  in
    {service = name;}
    // lib.optionalAttrs (attr != "") {inherit attr;};

  # `simple 31337`              -> { port = 31337; }
  # `simple "test.lan:31337"`   -> { host = "test.lan"; port = 31337; }
  simple = spec:
    if builtins.isInt spec
    then {port = spec;}
    else if builtins.isString spec
    then
      if lib.hasInfix ":" spec
      then {
        host = lib.head (lib.splitString ":" spec);
        port = lib.toInt (lib.last (lib.splitString ":" spec));
      }
      else {port = lib.toInt spec;}
    else throw "simple: expected int or string, got ${builtins.typeOf spec}";

  glowingBearCaddy = ''
    # Proxy WebSocket connections at /weechat to WeeChat relay on port 9001
    reverse_proxy /weechat 127.0.0.1:9001 {
      flush_interval -1
    }
    root * ${pkgs.glowing-bear}
    file_server
  '';
  weechatCaddy = ''
    reverse_proxy http://127.0.0.1:9000 {
      flush_interval -1
    }
  '';
in {
  sops.secrets.caddy_env = {};
  networking.firewall.allowedTCPPorts = [80 443];
  users.users.caddy.extraGroups = [config.services.tailscaleAuth.group];
  services.caddy = {
    enable = true;
    adapter = "caddyfile";
    resume = false;
    package = pkgs.caddy.withPlugins {
      plugins = [
        # "github.com/tailscale/caddy-tailscale@v0.0.0-20250508175905-642f61fea3cc"
        "github.com/greenpau/caddy-security@v1.1.64"
        #"go.akpain.net/caddy-tailscale-auth@v0.1.7"
        "github.com/enum-gg/caddy-discord@v1.2.0"
        "github.com/caddy-dns/cloudflare@v0.2.4"
        "github.com/mholt/caddy-webdav@v0.0.0-20260127042217-fa2f366b0d75"
      ];
      hash = "sha256-HoyMiTx3K/IQsLAwxVW4fsekWaLNkohYZywEqPGhst0=";
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
          search = service "searx:settings.server.port";
          baby = container "babybuddy:8234";
          news = simple 8752;
          disks = service "scrutiny:settings.web.listen.port";
          prometheus = service "prometheus";
          photos = service "immich";
          monitoring = service "grafana:settings.server.http_port";
          cadvisor = service "cadvisor";
          code = service "forgejo:settings.server.HTTP_PORT";
          # files = service "copyparty:p";
          ldap = service "lldap:settings.http_port";
          auth = service "authentik:settings.listen.http";
          # auth = service "tinyauth:settings.SERVER_PORT";
          calibre = service "calibre-server";
          books = service "calibre-web:listen.port";
          lounge = service "thelounge";
          # tty = service "ttyd";
          glance = service "glance:settings.server.port";
          wiki = service "gollum";
          docs = service "paperless";
          # yt = service "pinchflat";
          podcasts = service "audiobookshelf";
        }
        // (lib.optionalAttrs (tvstack != {}) {
          torrent = simple "${tvstack.hostAddress}:5123";
          sonarr = simple tvstack_svc.sonarr.settings.server.port;
          radarr = simple tvstack_svc.radarr.settings.server.port;
          lidarr = simple tvstack_svc.lidarr.settings.server.port;
          bazarr = simple tvstack_svc.bazarr.listenPort;
          prowlarr = simple tvstack_svc.prowlarr.settings.server.port;
        });
      extraHosts = {
        # "*.proxy.${hostname}.${tld.local}:80, *.proxy.${hostname}.${tld.ts.local}:80".extraConfig = ''
        #   @hostnames header_regexp host Host ([0-9]+)\..*
        #   handle @hostnames {
        #     import auth talos user {
        #       reverse_proxy 127.0.0.1:{http.regexp.host.1}
        #     }
        #   }
        # '';
        "${mkHostnames {name = "files";}}".extraConfig = ''
          import auth talos admin {
            webdav /* {
              root /mnt/data/
              prefix /
            }
          }
        '';
        "${mkHostnames {name = "tailscale";}}".extraConfig = ''
          forward_auth unix/${config.services.tailscaleAuth.socketPath} {
            uri /auth
            header_up Remote-Addr {remote_host}
            header_up Remote-Port {remote_port}
            header_up Original-URI {uri}
            copy_headers {
              Tailscale-User>X-Webauth-User
              Tailscale-Name>X-Webauth-Name
              Tailscale-Login>X-Webauth-Login
              Tailscale-Tailnet>X-Webauth-Tailnet
              Tailscale-Profile-Picture>X-Webauth-Profile-Picture
            }
          }
          header X-Webauth-User {http.request.header.X-Webauth-User}
          header X-Webauth-Name {http.request.header.X-Webauth-Name}
          header X-Webauth-Login {http.request.header.X-Webauth-Login}
          header X-Webauth-Tailnet {http.request.header.X-Webauth-Tailnet}
          header X-Webauth-Profile-Picture {http.request.header.X-Webauth-Profile-Picture}
          respond "HI!" 200
        '';
        "blog.talos.lan:80".extraConfig = ''
          root /var/www/blog.talos.lan/
          handle_errors {
          	rewrite /{err.status_code}.html
          	file_server
          }
          file_server
        '';
        "earthnuker.xyz:443, earthnuker.xyz:80".extraConfig = ''
          import tls
          root /var/www/earthnuker.xyz/
          handle_errors {
          	rewrite /{err.status_code}.html
          	file_server
          }
          file_server
        '';
        # "auth.earthnuker.xyz:443".extraConfig = ''
        #     forward_auth 127.0.0.1:3479 {
        #       uri /api/auth/caddy
        #       copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        #   }
        # '';
        "*.earthnuker.xyz:80, *.earthnuker.xyz:443".extraConfig = ''
          import tls
          respond "Hi from {http.request.host} in {http.request.duration}!" 200
        '';
        "${mkHostnames {name = "irc";}}".extraConfig = glowingBearCaddy;
        "${mkHostnames {name = "wc";}}".extraConfig = weechatCaddy;
        "${mkHostnames {name = "home";}}".extraConfig = "reverse_proxy http://127.0.0.1:${toString config.services.homepage-dashboard.listenPort}";
      };
    };
  };
}

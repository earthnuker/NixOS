# Caddy + Anubis

The least disruptive adaptation is to teach your existing `mkCaddy` helper about `anubis = true`. Protected sites get two Caddy vhosts automatically: the normal public vhost proxies to the single Anubis instance, and a loopback-only vhost on port `8924` contains the original backend/auth configuration.

This avoids changing the bulk of your service declarations.

```nix
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
    duckdns = "${builtins.elemAt config.services.duckdns.domains 0}.duckdns.org";
    local = "lan";
  };

  # Caddy -> Anubis
  anubisBindHost = "127.0.0.1";
  anubisBindPort = 8923;

  # Anubis -> same Caddy process
  anubisUpstreamHost = "127.0.0.1";
  anubisUpstreamPort = 8924;

  /*
   * Hostnames without Caddy ports.
   *
   * foo -> [
   *   "foo.talos.ts"
   *   "foo.talos.lan"
   * ]
   */
  mkHosts = {
    name ? "",
    suffixes ? [
      tld.ts.local
      tld.local
    ],
  }:
    map (
      suffix:
        "${lib.optionalString (name != "") "${name}."}${hostname}.${suffix}"
    )
    suffixes;

  /*
   * Existing public site-address format.
   */
  mkHostnames = {
    name ? "",
    suffixes ? [
      tld.ts.local
      tld.local
    ],
    ports ? [80],
  }:
    lib.concatStringsSep ", " (
      lib.concatMap
      (
        host:
          map
          (port: "${host}:${toString port}")
          ports
      )
      (mkHosts {
        inherit name suffixes;
      })
    );

  /*
   * Internal Caddy vhosts used as Anubis' single TARGET.
   *
   * The Host header still contains foo.talos.lan etc., so Caddy can
   * perform ordinary name-based virtual-host routing here.
   */
  mkAnubisUpstreamHostnames = hosts:
    lib.concatStringsSep ", " (
      map
      (host: "http://${host}:${toString anubisUpstreamPort}")
      hosts
    );

  /*
   * The only public -> Anubis proxy config we need.
   *
   * Caddy already handles:
   *   X-Forwarded-For
   *   X-Forwarded-Proto
   *   X-Forwarded-Host
   *
   * and preserves Host when proxying over HTTP.
   */
  anubisProxyConfig = ''
    reverse_proxy http://${anubisBindHost}:${toString anubisBindPort} {
      header_up X-Real-Ip {client_ip}
      header_up X-Http-Version {http.request.proto}
    }
  '';

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

    /*
     * Generate one of your normal services.
     *
     * New attribute:
     *
     *   anubis = true;
     *
     * When false/absent, behaviour is exactly as before.
     */
    mkHost = name: let
      app_info = apps.${name};

      attrPath =
        [(app_info.service or "#")]
        ++ (lib.splitString "." (app_info.attr or "port"));

      proto = app_info.proto or "http";

      port =
        lib.attrByPath
        attrPath
        (app_info.port or (-1))
        config.services;

      host = app_info.host or "127.0.0.1";

      inner = lib.concatStringsSep "\n" [
        commonConfig
        (extraConfigPre.${name} or "")
        "reverse_proxy ${proto}://${host}:${toString port}"
        (extraConfigPost.${name} or "")
      ];

      group = app_info.auth or null;

      backendConfig =
        if group != null
        then mkAuth {
          inherit group inner;
        }
        else inner;

      protected = app_info.anubis or false;

      suffixes =
        app_info.suffixes or [
          tld.ts.local
          tld.local
        ];

      ports = app_info.ports or [80];

      publicHosts = mkHosts {
        inherit name suffixes;
      };

      publicAddress = mkHostnames {
        inherit name suffixes ports;
      };

      internalAddress =
        mkAnubisUpstreamHostnames publicHosts;
    in
      assert lib.assertMsg (
        port != -1
      ) "invalid port for ${name} at ${lib.concatStringsSep "." attrPath}";

      if protected
      then {
        /*
         * Public side:
         *
         * client -> Caddy -> Anubis
         */
        "${publicAddress}" = {
          extraConfig = anubisProxyConfig;
        };

        /*
         * Private side:
         *
         * Anubis -> Caddy -> auth/backend
         *
         * Same Caddy process, different listener.
         */
        "${internalAddress}" = {
          extraConfig = ''
            bind ${anubisUpstreamHost}

            ${backendConfig}
          '';
        };
      }
      else {
        "${publicAddress}" = {
          extraConfig = backendConfig;
        };
      };

    /*
     * extraHosts are also allowed to use:
     *
     *   anubis = true;
     *   anubisHosts = [ "example.com" ];
     *
     * Those two attributes are consumed here and never reach the
     * NixOS Caddy module.
     */
    mkExtraHost = publicAddress: value: let
      protected = value.anubis or false;
      hosts = value.anubisHosts or [];

      cleanValue =
        builtins.removeAttrs value [
          "anubis"
          "anubisHosts"
        ];

      backendConfig = cleanValue.extraConfig or "";

      internalAddress =
        mkAnubisUpstreamHostnames hosts;
    in
      if protected
      then
        assert lib.assertMsg
        (hosts != [])
        "Anubis-protected extraHost ${publicAddress} needs anubisHosts";
        {
          /*
           * Keep things such as useACMEHost/serverAliases/etc. on the
           * public vhost, but replace its request handlers with Anubis.
           */
          "${publicAddress}" =
            cleanValue
            // {
              extraConfig = anubisProxyConfig;
            };

          "${internalAddress}" = {
            extraConfig = ''
              bind ${anubisUpstreamHost}

              ${backendConfig}
            '';
          };
        }
      else {
        "${publicAddress}" = cleanValue;
      };

    generatedApps =
      lib.mergeAttrsList (
        map mkHost (builtins.attrNames apps)
      );

    generatedExtraHosts =
      lib.mergeAttrsList (
        lib.mapAttrsToList mkExtraHost extraHosts
      );
  in
    generatedApps // generatedExtraHosts;

  glowingBearCaddy = ''
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

  users.users.caddy.extraGroups = [
    config.services.tailscaleAuth.group
  ];

  /*
   * ONE Anubis.
   *
   * It has ONE target: the private Caddy listener.
   *
   * It does not need to know where Grafana, Axum, Quart, Zola, etc.
   * actually live.
   */
  services.anubis.instances.main = {
    enable = true;

    settings = {
      BIND = "${anubisBindHost}:${toString anubisBindPort}";
      BIND_NETWORK = "tcp";

      TARGET =
        "http://${anubisUpstreamHost}:${toString anubisUpstreamPort}";

      METRICS_BIND = "127.0.0.1:9090";
      METRICS_BIND_NETWORK = "tcp";

      SERVE_ROBOTS_TXT = false;

      # Adjust as desired.
      DIFFICULTY = 4;
    };
  };

  services.caddy = {
    enable = true;
    adapter = "caddyfile";
    resume = false;

    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/greenpau/caddy-security@v1.1.64"
        "github.com/enum-gg/caddy-discord@v1.2.0"
        "github.com/caddy-dns/cloudflare@v0.2.4"
        "github.com/mholt/caddy-webdav@v0.0.0-20260127042217-fa2f366b0d75"
      ];

      hash = "sha256-6m1kcrXj+7hcr+TcTYQpt4tVyAhYwfG94045SUD9Vyc=";
    };

    environmentFile = config.sops.secrets.caddy_env.path;

    logFormat = lib.mkForce ''
      format console
      level DEBUG
    '';

    /*
     * Important for the Anubis -> Caddy -> application hop.
     *
     * Anubis connects to the internal listener from 127.0.0.1.
     * Trusting that proxy lets Caddy preserve the existing XFF chain
     * when it subsequently reverse_proxies to Quart/Axum/etc.
     *
     * This is listener-specific; it does not cause your Internet-facing
     * Caddy listener to trust arbitrary RFC1918 clients.
     */
    globalConfig = ''
      ${lib.readFile ./global_config}

      servers ${anubisUpstreamHost}:${toString anubisUpstreamPort} {
        trusted_proxies static 127.0.0.1/8
        trusted_proxies_strict
      }
    '';

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

          news = {
            port = 8752;
          };

          disks = {
            service = "scrutiny";
            attr = "settings.web.listen.port";
          };

          prometheus = {
            service = "prometheus";
          };

          photos = {
            service = "immich";
          };

          monitoring = {
            service = "grafana";
            attr = "settings.server.http_port";
          };

          cadvisor = {
            service = "cadvisor";
          };

          code = {
            service = "forgejo";
            attr = "settings.server.HTTP_PORT";
          };

          ldap = {
            service = "lldap";
            attr = "settings.http_port";
          };

          calibre = {
            service = "calibre-server";
            attr = "port";
          };

          books = {
            service = "calibre-web";
            attr = "listen.port";
          };

          lounge = {
            service = "thelounge";
          };

          glance = {
            service = "glance";
            attr = "settings.server.port";
          };

          wiki = {
            service = "gollum";
          };

          docs = {
            service = "paperless";
          };

          podcasts = {
            service = "audiobookshelf";
          };
        }
        // (lib.optionalAttrs (tvstack != {}) {
          torrent = {
            port = 5123;
            host = tvstack.hostAddress;
          };

          sonarr = {
            inherit (tvstack_svc.sonarr.settings.server) port;
          };

          radarr = {
            inherit (tvstack_svc.radarr.settings.server) port;
          };

          lidarr = {
            inherit (tvstack_svc.lidarr.settings.server) port;
          };

          bazarr = {
            port = tvstack_svc.bazarr.listenPort;
          };

          prowlarr = {
            inherit (tvstack_svc.prowlarr.settings.server) port;
          };
        });

      extraHosts = {
        "${mkHostnames {name = "test";}}".extraConfig = ''
          reverse_proxy {
            dynamic a babybuddy.dns.podman 80
          }
        '';

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

          respond "HI!" 200
        '';

        /*
         * LAN blog remains direct.
         */
        "blog.talos.lan:80".extraConfig = ''
          root /var/www/blog.talos.lan/

          handle_errors {
            rewrite /{err.status_code}.html
            file_server
          }

          file_server
        '';

        /*
         * Public Zola blog:
         *
         * public Caddy
         *   -> one Anubis
         *   -> private Caddy :8924
         *   -> file_server
         */
        "earthnuker.xyz" = {
          anubis = true;
          anubisHosts = [
            "earthnuker.xyz"
          ];

          extraConfig = ''
            root /var/www/earthnuker.xyz/

            handle_errors {
              rewrite /{err.status_code}.html
              file_server
            }

            file_server
          '';
        };

        /*
         * You could protect this too, but I wouldn't bother if it's
         * literally just the diagnostic response.
         */
        "*.earthnuker.xyz" = {
          extraConfig = ''
            respond "Hi from {http.request.host} in {http.request.duration}!" 200
          '';
        };

        "${mkHostnames {name = "irc";}}".extraConfig =
          glowingBearCaddy;

        "${mkHostnames {name = "wc";}}".extraConfig =
          weechatCaddy;

        "${mkHostnames {name = "home";}}".extraConfig =
          "reverse_proxy http://127.0.0.1:${toString config.services.homepage-dashboard.listenPort}";
      };
    };
  };
}
```

Then exposing one of your generated apps through Anubis is just:

```nix
someApp = {
  port = 8000;
  anubis = true;
};
```

That produces conceptually:

```caddyfile
someApp.talos.lan:80 {
    reverse_proxy 127.0.0.1:8923
}

http://someApp.talos.lan:8924 {
    bind 127.0.0.1
    reverse_proxy 127.0.0.1:8000
}
```

If the app also has your `auth` field, the generated path becomes:

```text
client
  |
  v
public Caddy
  |
  v
Anubis
  |
  v
internal Caddy
  |
  v
caddy-security auth
  |
  v
Quart / Axum / whatever
```

which is the order I'd want: bots get dealt with before you spend resources on authentication.

For `earthnuker.xyz`, I deliberately changed your address from:

```nix
"earthnuker.xyz:80"
```

to:

```nix
"earthnuker.xyz"
```

because that tells Caddy to own HTTPS and do automatic TLS. If something else is deliberately terminating public TLS in front of this Caddy instance, keep your existing `earthnuker.xyz:80` instead. Caddy site addresses with a hostname match on the HTTP `Host`, and `bind 127.0.0.1` confines the internal listener to loopback. ([Caddy Web Server][1])

The reason one Anubis works here despite Anubis not supporting a different `TARGET` per site is that we don't ask it to. `TARGET` is always `127.0.0.1:8924`; Caddy performs the second routing step. Anubis' own reverse-proxy documentation explicitly describes reusing one instance for multiple websites in this arrangement. ([GitHub][2]) The open multi-service issue is about having Anubis itself dynamically choose unrelated targets, which this architecture avoids. ([GitHub][3])

One detail worth keeping is the loopback-specific `trusted_proxies` stanza. Caddy normally sanitizes incoming `X-Forwarded-*` values unless the immediate proxy is trusted; on the internal listener, the immediate proxy is Anubis. Caddy documents both this behavior and the `{client_ip}` placeholder used above. ([Caddy Web Server][4])

I would keep `8923`, `8924`, and `9090` out of `networking.firewall.allowedTCPPorts`; all three are loopback-only. Only `80` and `443` remain externally reachable.

[1]: https://caddyserver.com/docs/caddyfile/concepts?utm_source=chatgpt.com "Caddyfile Concepts — Caddy Documentation"
[2]: https://github.com/TecharoHQ/anubis/blob/main/docs/docs/admin/environments/nginx.mdx?utm_source=chatgpt.com "anubis/docs/docs/admin/environments/nginx.mdx at main · TecharoHQ/anubis · GitHub"
[3]: https://github.com/TecharoHQ/anubis/issues/555?utm_source=chatgpt.com "Add multiple service support · Issue #555 · TecharoHQ/anubis · GitHub"
[4]: https://caddyserver.com/docs/caddyfile/directives/reverse_proxy?utm_source=chatgpt.com "reverse_proxy (Caddyfile directive) — Caddy Documentation"

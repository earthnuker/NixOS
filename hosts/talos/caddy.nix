{
  config,
  lib,
  ...
}: let
  tailnet = "possum-gila.ts.net";
  hostname = config.networking.hostName;
  localTld = "lan";
  mkCaddy = {
    apps,
    extraConfig,
    extraHosts,
  }:
    builtins.listToAttrs (
      map (name: {
        name = "${name}.${hostname}.${localTld}:80";
        value = {
          extraConfig =
            ''reverse_proxy http://127.0.0.1:${toString apps.${name}}''
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
    virtualHosts = mkCaddy {
      apps = {
        hydra = 8081;
        linkding = 9090;
        ha = 8123;
        n8n = 5678;
      };
      extraConfig = {
      };
      extraHosts = {
        "${hostname}.${tailnet}.net:80".extraConfig = ''
          # reverse_proxy 127.0.0.1:8081
          respond "Hello from {hostport} to {header.X-Forwarded-For}"
        '';
      };
    };
  };
}

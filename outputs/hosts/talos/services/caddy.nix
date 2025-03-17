{
  config,
  lib,
  ...
}: let
  tailnet = "possum-gila.ts.net";
  hostname = config.networking.hostName;
  localTld = "lan";
  mkCaddy = {
    apps ? {},
    extraConfig ? {},
    extraHosts ? {},
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
        torrent = 8080;
        sonarr = 8989;
        radarr = 7878;
        bazarr = 6767;
        prowlarr = 9696;
      };
      extraHosts = {
        "${hostname}.${localTld}:80".extraConfig = ''
          reverse_proxy http://127.0.0.1:8082
        '';
        "${hostname}.${tailnet}:80".extraConfig = ''
          # reverse_proxy 127.0.0.1:8081
          respond "Hello from {hostport} to {header.X-Forwarded-For}"
        '';
      };
    };
  };
}

{...}: {
  services.caddy = {
    enable = true;
    adapter = "caddyfile";
    globalConfig = ''
      auto_https off
    '';
    virtualHosts = {
      "hydra.talos.lan:80".extraConfig = ''
        reverse_proxy http://127.0.0.1:8081
      '';
      "linkding.talos.lan:80".extraConfig = ''
        reverse_proxy http://127.0.0.1:9090
      '';
    };
  };
}

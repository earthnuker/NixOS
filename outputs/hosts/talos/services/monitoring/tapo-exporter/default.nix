{
  pkgs,
  config,
  ...
}: let
  prometheus-tapo-exporter = pkgs.buildGoModule {
    pname = "prometheus-tapo-exporter";
    version = "main";
    src = pkgs.fetchFromGitHub {
      owner = "tess1o";
      repo = "go-tapo-exporter";
      rev = "main";
      sha256 = "sha256-d+RmzDKIXAJgOtQ30MsPkv7CeK12pv+ljaxj6Q8JsA0=";
    };
    vendorHash = "sha256-d1W9k5vDraIDy+qH3pr1GpBTDD4N+taCsBwgqk3z1dA=";
  };
in {
  sops.secrets.tapo_exporter_json = {};
  systemd.services.prometheus-tapo-exporter = {
    description = "Prometheus exporter for TP-Link's Tapo P100/P110 smart plugs ";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Restart = "always";
      ProtectSystem = "full";
      PrivateTmp = "true";
    };
    script = ''
      ${prometheus-tapo-exporter}/bin/prometheus-tapo-exporter  \
        -c ${config.sops.secrets.tapo_exporter_json.path}
    '';
  };
}

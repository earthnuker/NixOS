{
  pkgs,
  config,
  ...
}: let
  prometheus-tapo-exporter = pkgs.buildGoModule {
    pname = "prometheus-tapo-exporter";
    version = "main";
    src = pkgs.fetchFromGitHub {
      owner = "insomniacslk";
      repo = "prometheus-tapo-exporter";
      rev = "main";
      sha256 = "sha256-DU8yb0e7WQU7QxHyb3WPQV59oIJyQU5ZIEUJsoKoGcA=";
    };
    vendorHash = "sha256-o5blx0dZgUZSwgFVVLXM2wHhcWMHfWcrBuTfUWuPvZ8=";
  };
in {
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

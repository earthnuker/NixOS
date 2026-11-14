{
  pkgs,
  lib,
  config,
  ...
}: let
  tapo-exporter = pkgs.buildGoModule {
    pname = "go-tapo-exporter";
    version = "0.0.3";

    src = pkgs.fetchFromGitHub {
      owner = "tess1o";
      repo = "go-tapo-exporter";
      rev = "v0.0.3";
      hash = "sha256-8fP0rs7L7YLD/BLDESwkLQEnE3+mT2zK04IXcvwBrHQ=";
    };
    vendorHash = "sha256-WvTh0gsd0RYVenPbpQF+dEdrIcx8J/pRR2HDev6z8iI=";
     postPatch = ''
      substituteInPlace main.go \
        --replace-fail '"8086"' '"9105"'
    '';
  };
in {
  sops.secrets.tapo_exporter_env = {
    restartUnits = ["tapo-exporter.service"];
  };
  # devices JSON no longer contains credentials, so 0444 is fine
  sops.secrets.tapo_devices_json = {
    mode = "0444";
    restartUnits = ["tapo-exporter.service"];
  };

  systemd.services.tapo-exporter = {
    description = "Prometheus exporter for TP-Link Tapo smart plugs";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target" "sops-nix.service"];

    serviceConfig = {
      ExecStart = "${tapo-exporter}/bin/go-tapo-exporter";
      EnvironmentFile = config.sops.secrets.tapo_exporter_env.path;
      Environment = [
        "TAPO_CONFIG_LOCATION=${config.sops.secrets.tapo_devices_json.path}"
      ];
      DynamicUser = true;
      Restart = "always";
      RestartSec = 10;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
    };
  };

}
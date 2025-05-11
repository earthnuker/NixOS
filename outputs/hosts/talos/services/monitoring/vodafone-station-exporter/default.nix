{
  pkgs,
  config,
  ...
}: let
  vodafone-station-exporter = pkgs.buildGoModule {
    pname = "vodafone-station-exporter";
    version = "main";
    src = pkgs.fetchFromGitHub {
      # owner = "earthnuker";
      # repo = "vodafone-station-exporter";
      # rev = "main";
      owner = "gmk6351";
      repo = "vodafone-station-exporter";
      rev = "master";
      sha256 = "sha256-uJnz9xgjaGfMB0a7tWwpmaOpSxd1/MtM4J72ojGCtuY=";
    };
    vendorHash = "sha256-7x13EXc1dQwalQPlGBN6y6YYB0DiKgkqCcYt4JhOsGg=";
  };
in {
  systemd.services.prometheus-vodafone-station-exporter = {
    description = "Vodafone Station (CGA4233DE) Prometheus Exporter";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Restart = "always";
      ProtectSystem = "full";
      PrivateTmp = "true";
      # User = "vodafone-station-exporter";
      # Group = "vodafone-station-exporter";
    };
    script = ''
      ${vodafone-station-exporter}/bin/vodafone-station-exporter \
        -web.listen-address 127.0.0.1:9420 \
        -vodafone.station-password "$(cat ${config.sops.secrets.vodafone_station_passwd.path})"
    '';
  };
}

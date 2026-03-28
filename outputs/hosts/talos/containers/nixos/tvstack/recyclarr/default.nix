{config', ...}: {
  imports = [
    ./radarr.nix
    ./sonarr.nix
  ];
  systemd.services.recyclarr.serviceConfig.LoadCredential = [
    "RADARR_API_KEY:${config'.sops.secrets.radarr_api_key.path}"
    "SONARR_API_KEY:${config'.sops.secrets.sonarr_api_key.path}"
  ];
  services.recyclarr.enable = true;
}

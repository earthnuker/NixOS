{
  lib,
  config,
  ...
} @ inputs: let
  sonarr_api_key = builtins.readFile config.age.secrets.sonarr_api_key.path;
  radarr_api_key = builtins.readFile config.age.secrets.radarr_api_key.path;
in {
  services.recyclarr = {
    enable = true;
    configuration = {
      sonarr.shows = (import ./sonarr.nix) // {api_key = sonarr_api_key;};
      radarr.movies = (import ./radarr.nix) // {api_key = radarr_api_key;};
    };
  };
}

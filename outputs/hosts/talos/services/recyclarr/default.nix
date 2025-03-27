{lib, ...} @ inputs: {
  /*
  TODO: Add the `recyclarr` service
  */
  services.recyclarr = {
    enable = true;
    configuration = {
      sonarr.shows = import ./sonarr.nix inputs;
      radarr.movies = import ./radarr.nix inputs;
    };
  };
}

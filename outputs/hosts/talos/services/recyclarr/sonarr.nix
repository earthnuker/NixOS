{
  base_url = "http://localhost:8989";
  api_key = {
    _secret = "/run/credentials/recyclarr.service/SONARR_API_KEY";
  };
  quality_definition = {
    type = "series";
  };
  delete_old_custom_formats = true;
  media_naming = {
    series = "default";
    season = "default";
    episodes = {
      rename = true;
      standard = "default";
      daily = "default";
      anime = "default";
    };
  };
  include = [
    {template = "sonarr-v4-custom-formats-anime";}
    {template = "sonarr-v4-custom-formats-web-1080p";}
    {template = "sonarr-quality-definition-anime";}
    {template = "sonarr-quality-definition-series";}
    {template = "sonarr-v4-quality-profile-anime";}
    {template = "sonarr-v4-quality-profile-web-1080p-alternative";}
  ];
}

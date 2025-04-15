{
  base_url = "http://localhost:7878";
  api_key = {_secret = "/run/credentials/recyclarr.service/RADARR_API_KEY";};
  delete_old_custom_formats = true;
  replace_existing_custom_formats = true;
  media_naming = {
    folder = "default";
    movie = {
      rename = true;
      standard = "default";
    };
  };
  include = [
    {template = "radarr-custom-formats-hd-bluray-web";}
    {template = "radarr-custom-formats-anime";}
    {template = "radarr-quality-definition-movie";}
    {template = "radarr-quality-profile-hd-bluray-web";}
    {template = "radarr-quality-profile-anime";}
  ];
}

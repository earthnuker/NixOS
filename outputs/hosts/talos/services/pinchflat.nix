{config, ...}: {
  services.pinchflat = {
    enable = true;
    secretsFile = config.sops.secrets.pinchflat.path;
    mediaDir = "/mnt/data/media/youtube/";
    selfhosted = true;
  };
}

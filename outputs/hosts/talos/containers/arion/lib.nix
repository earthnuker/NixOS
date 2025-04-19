let
  userId = 1000;
  groupId = 1000;
  globalEnv = {
    TZ = "Europe/Berlin";
    PUID = toString userId;
    PGID = toString groupId;
  };
in rec {
  containerVolumes = {
    config = "/mnt/data/config";
    media = "/mnt/data/media";
    downloads = "/mnt/data/downloads";
  };
  mkService = {
    image,
    hostname,
    ports ? [],
    exposed_ports ? [],
    volumes ? [],
    environment ? {},
    configDir ? "/config",
    extraArgs ? {},
    extraServiceArgs ? {},
  }:
    {
      service =
        {
          inherit image hostname;
          ports = (map (port: "127.0.0.1:${toString port}:${toString port}") ports) ++ (map (port: "${toString port}:${toString port}") exposed_ports);
          volumes =
            [
              "${containerVolumes.config}/${hostname}:${configDir}"
            ]
            ++ volumes;
          environment = globalEnv // environment;
        }
        // extraServiceArgs;

      out = {
        service = {
          pull_policy = "always";
        };
      };
    }
    // extraArgs;
}

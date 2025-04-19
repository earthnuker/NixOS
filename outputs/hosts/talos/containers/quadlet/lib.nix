{
  config,
  lib,
  ...
} @ inputs: let
  quadlet = config.virtualisation.quadlet;
  containerVolumes = {
    config = "/mnt/data/config";
    media = "/mnt/data/media";
    downloads = "/mnt/data/downloads";
  };
  userId = 1000;
  groupId = 1000;
  globalEnv = {
    TZ = "Europe/Berlin";
    PUID = toString userId;
    PGID = toString groupId;
  };
  toLocalPort = port: "127.0.0.1:${toString port}:${toString port}";
  mkService = {
    image,
    name,
    autoStart ? true,
    ports ? [],
    volumes ? [],
    environment ? {},
    configDir ? "/config",
    pod ? null,
    extraContainerArgs ? {},
    extraServiceArgs ? {},
  }: {
    inherit autoStart;
    containerConfig =
      {
        # Defaults
        inherit image name;
        pod = lib.optionalString (pod != null) quadlet.pods.${pod}.ref;
        volumes =
          [
            "${containerVolumes.config}/${name}:${configDir}"
          ]
          ++ volumes;
        environments = globalEnv // environment;
        publishPorts = map toLocalPort ports;
        startWithPod = true;
      }
      // extraContainerArgs; # Overrides
    serviceConfig =
      {
        # Defaults
        RestartSec = "10";
        Restart = "always";
      }
      // extraServiceArgs; # Overrides
  };
in {
  inherit containerVolumes;
  mkPod = pod_name: {
    services,
    extraPodConfig ? {},
  }: let
    publishPorts = map toLocalPort (lib.unique (lib.concatMap (svc: svc.ports or []) (lib.attrValues services)));
    mkContainer = name: value:
      mkService ((lib.removeAttrs value ["ports"])
        // {
          pod = pod_name;
          name = "${pod_name}-${name}";
        });
  in {
    containers = lib.mapAttrs mkContainer services;
    pods."${pod_name}" = {
      podConfig = {inherit publishPorts;} // extraPodConfig;
    };
  };
}

{
  image = "ghcr.io/home-assistant/home-assistant:stable";
  hostname = "homeassisstant";
  privileged = true;
  extraOptions = [
    "--network=host"
  ];
  environment = {
    TZ = "Europe/Berlin";
  };
  volumes = [
    "/tank/ha:/config"
    "/run/dbus:/run/dbus:ro"
  ];
}

{
  image = "traefik/whoami";
  hostname = "whoami";
  ports = [
    "8081:8081"
  ];
  environment = {
    WHOAMI_PORT_NUMBER = "8081";
  };
}

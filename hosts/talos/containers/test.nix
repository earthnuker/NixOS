{
  image = "traefik/whoami";
  hostname = "test";
  ports = [
    "8081:8081"
  ];
  environment = {
    WHOAMI_PORT_NUMBER = "8081";
  };
}

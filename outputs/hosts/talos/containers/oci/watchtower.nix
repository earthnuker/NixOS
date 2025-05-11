_: {
  image = "containrrr/watchtower:latest";
  hostname = "watchtower";
  volumes = [
    "/var/run/docker.sock:/var/run/docker.sock"
  ];
}

{
  image = "sissbruecker/linkding:latest";
  hostname = "linkding";
  ports = [
    "9090:9090"
  ];
  volumes = [
    "/tank/data/linkding:/etc/linkding/data"
  ];
}

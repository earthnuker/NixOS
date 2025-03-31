{
  image = "sissbruecker/linkding:latest";
  hostname = "linkding";
  ports = [
    "9090:9090"
  ];
  volumes = [
    "/mnt/data/data/linkding:/etc/linkding/data"
  ];
}

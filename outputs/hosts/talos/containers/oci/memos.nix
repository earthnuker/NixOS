{
  image = "neosmemo/memos:stable";
  hostname = "memos";
  ports = [
    "127.0.0.1:5230:5230"
  ];
  environment = {
  };
  volumes = [
    "/var/lib/memos:/var/opt/memos"
  ];
}

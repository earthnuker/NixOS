{
  image = "lscr.io/linuxserver/babybuddy";
  hostname = "babybuddy";
  ports = [
    "127.0.0.1:8234:8000"
  ];
  environment = {
    "CSRF_TRUSTED_ORIGINS" = "http://127.0.0.1:8000";
    "TZ" = "Europe/Berlin";
  };
  volumes = [
    "/var/lib/babybuddy:/config"
  ];
}

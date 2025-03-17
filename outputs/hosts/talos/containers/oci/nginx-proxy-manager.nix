{
  image = "jc21/nginx-proxy-manager:latest";
  hostname = "nginx-proxy-manager";
  ports = [
    "80:80"
    "81:81"
  ];
  volumes = [
    "./letsencrypt:/etc/letsencrypt"
  ];
}

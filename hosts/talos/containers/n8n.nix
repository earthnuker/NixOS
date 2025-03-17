{
  image = "n8nio/n8n:latest";
  hostname = "n8n";
  ports = [
    "5678:5678"
  ];
  volumes = [
  ];
  environment = {
    N8N_SECURE_COOKIE = "false";
  };
}

{
  image = "ghcr.io/usememos/memogram:latest";
  hostname = "memogram";
  environment = {
    SERVER_ADDR = "dns:notes.talos.lan";
    BOT_TOKEN = "";
  };
}

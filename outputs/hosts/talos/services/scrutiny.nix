{
  services.scrutiny = {
    enable = true;
    collector.enable = true;
    settings = {
      web.listen = {
        port = 8753;
        host = "127.0.0.1";
      };
      openFirewall = false;
    };
  };
}

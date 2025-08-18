{config, ...}: {
  services.nats = {
    enable = true;
    validateConfig = true;
    jetstream = true;
    serverName = config.networking.hostName;
    settings = {
      http_port = 8222;
      #authorization.token = "DEADBEEF";
      system_account = "SYS";
      accounts.USERS.users = [
        {
          user = "user";
          password = "user";
        }
      ];
      accounts.SYS.users = [
        {
          user = "admin";
          password = "admin";
        }
      ];
    };
  };
}

_: {
  services.forgejo = {
    enable = false;
    database.type = "postgres";
    settings = {
      server = rec {
        DOMAIN = "code.talos.lan";
        ROOT_URL = "%(PROTOCOL)s://%(DOMAIN)s/";
        HTTP_PORT = 3001;
      };
      cache.ADAPTER = "twoqueue";
      service = {
        DISABLE_REGISTRATION = false;
      };
      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "github";
      };
      mailer = {
        ENABLED = false;
      };
    };
  };
}

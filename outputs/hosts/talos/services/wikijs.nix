{
  services = {
    wiki-js = {
      enable = true;
      settings = {
        port = 4568;
        db = {
          db = "wiki-js";
          host = "localhost";
          user = "wiki-js";
          type = "postgres";
        };
      };
    };
    postgresql = {
      ensureUsers = [
        {
          name = "wiki-js";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [
        "wiki-js"
      ];
    };
  };
}

{...} @ inputs: {
  services.postgres = {
    service = {
      image = "postgres:10";
      environment = {
        POSTGRES_PASSWORD = "mydefaultpass";
      };
    };
  };
}

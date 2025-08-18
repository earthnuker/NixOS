{config, ...}: {
  services.gotenberg.port = 3080;
  services.paperless = {
    enable = true;
    configureTika = true;
    domain = "docs.${config.networking.hostName}.lan";
    database.createLocally = true;
    consumptionDir = "/mnt/data/docs/in/";
    consumptionDirIsPublic = true;
    settings = {
      PAPERLESS_AUTO_LOGIN_USERNAME = "admin";
      PAPERLESS_OCR_LANGUAGE = "deu+eng";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
    };
    exporter = {
      enable = true;
      directory = "/mnt/data/docs/out/";
    };
  };
}

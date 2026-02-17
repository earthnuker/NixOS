_: {
  services = {
    calibre-server = {
      libraries = ["/mnt/data/media/books"];
      enable = true;
      port = 8456;
    };
    calibre-web = {
      enable = true;
      listen.ip = "0.0.0.0";
      options = {
        calibreLibrary = "/mnt/data/media/books";
        enableKepubify = true;
        enableBookUploading = true;
        enableBookConversion = true;
      };
    };
  };
}

_: {
  services.thelounge = {
    enable = true;
    port = 3333;
    extraConfig = {
      defaults = {
        name = "BJZ";
        host = "irc.bonerjamz.us";
        port = 6697;
      };
    };
  };
}

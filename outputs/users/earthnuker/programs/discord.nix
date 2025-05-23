{
  programs.nixcord = {
    enable = true;
    config = {
      frameless = true; # set some Vencord options
      useQuickCss = true;
    };
  };
}

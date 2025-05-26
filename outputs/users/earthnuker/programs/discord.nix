{
  programs.nixcord = {
    enable = true;
    discord.enable = false;
    vesktop.enable = true;
    config = {
      frameless = true; # set some Vencord options
      useQuickCss = true;
    };
  };
}

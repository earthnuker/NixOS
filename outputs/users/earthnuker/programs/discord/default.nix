{
  programs.vesktop = {
    enable = true;
    inherit (builtins.fromJSON (builtins.readFile ./vencord.json)) settings;
  };
}

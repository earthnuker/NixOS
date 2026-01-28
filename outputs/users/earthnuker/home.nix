{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./programs
    ./packages.nix
  ];
  nixpkgs.config = import ./nixpkgs-config.nix;
  xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;
  home = {
    stateVersion = "24.05";
    username = "earthnuker";
    homeDirectory = "/home/earthnuker";
    enableNixpkgsReleaseCheck = false;
    shell.enableZshIntegration = true;
    sessionVariables = {
      EDITOR = lib.mkForce "hx";
      VISUAL = lib.mkForce "code -n -w";
      ZSH_CACHE_DIR = "/home/earthnuker/.cache/oh-my-zsh";
      TERM = "wezterm";
      TERMINAL = "wezterm";
      DIRENV_WARN_TIMEOUT = 0;
    };
  };
  services = {
    ssh-agent.enable = true;
  };
  stylix.enableReleaseChecks = false;
  /*
  stylix.targets = {
    nixcord.enable = false;
    vencord.enable = false;
    vesktop.enable = false;
  };
  */
  xsession = {
    enable = true;
    initExtra = ''
      "${pkgs.dex}/bin/dex" -a
    '';
  };
}

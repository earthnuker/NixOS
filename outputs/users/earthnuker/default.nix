{
  pkgs,
  sources,
  root,
  ...
}: {
  imports = [
    ./programs
    ./packages.nix
  ];
  nixpkgs.config = import ./nixpkgs-config.nix;
  xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;
  home = {
    username = "earthnuker";
    homeDirectory = "/home/earthnuker";
    enableNixpkgsReleaseCheck = false;
    shell.enableZshIntegration = true;
    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "code -n -w";
      ZSH_CACHE_DIR = "/home/earthnuker/.cache/oh-my-zsh";
      TERM = "xterm-256color";
      TERMINAL = "kitty";
      DIRENV_WARN_TIMEOUT = 0;
      NSEARCH_FZF_CMD = "fzf --multi";
    };
  };
  xdg.configFile = {
    "awesome" = {
      recursive = true;
      source = "${root}/awesomewm";
    };
  };
  home.file = {
    ".config/awesome/lain".source = sources.lain.outPath;
    ".config/awesome/layout-machi".source = sources."layout-machi".outPath;
  };
  services = {
    ssh-agent.enable = true;
  };
  stylix.targets = {
    nixcord.enable = false;
    vencord.enable = false;
    vesktop.enable = false;
  };
  xsession = {
    enable = true;
    initExtra = ''
      "${pkgs.dex}/bin/dex" -a
    '';
  };
  home.stateVersion = "24.05";
}

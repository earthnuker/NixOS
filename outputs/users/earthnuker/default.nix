{
  pkgs,
  inputs,
  sources,
  root,
  ...
}: {
  imports = [
    ./programs
  ];
  home.enableNixpkgsReleaseCheck = false;
  nixpkgs.config = import ./nixpkgs-config.nix;
  xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;
  home = {
    username = "earthnuker";
    homeDirectory = "/home/earthnuker";
    packages = (import ./packages.nix) {inherit inputs pkgs;};

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "code -n -w";
      ZSH_CACHE_DIR = "/home/earthnuker/.cache/oh-my-zsh";
      TERM = "xterm-256color";
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

  xsession = {
    enable = false;
    initExtra = ''
      "${pkgs.dex}/bin/dex" -a
    '';
    windowManager.awesome = {
      enable = false;
      noArgb = true;
      package = pkgs.awesome.override {
        lua = pkgs.luajit;
      };
      luaModules = [
        pkgs.luajitPackages.luarocks
      ];
    };
    windowManager.i3 = {
      enable = false;
      package = pkgs.i3-gaps;
    };
  };
  stylix = {
    enable = false;
    image = ./wallpaper.jpg;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/spacemacs.yaml";
  };
  home.stateVersion = "24.05";
}

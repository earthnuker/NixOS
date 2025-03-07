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
    packages = with pkgs; [
      alejandra
      batmon
      btop
      dex
      eza
      dconf
      ffmpeg_7-full
      firefox
      iftop
      iotop
      micromamba
      fastfetch
      pandoc
      rustup
      cargo-binstall
      cargo-update
      zellij
      tmux
      vscode
      i3lock-fancy
      eww
      neovide
      tdesktop
      xss-lock
      python3Full
      starship
      rofi
      pavucontrol
      qemu
      networkmanager_dmenu
      nixpacks
      nix-inspect
      vim.xxd
      nnn
      just
      mitmproxy
      bettercap
      sd
      rsync
      grc
      inputs.nsearch.packages.${pkgs.system}.default
      (writeShellApplication {
        name = "nixdiff";
        runtimeInputs = [nvd nix-diff];
        text = ''
          set -euxo pipefail
          nix-diff --word-oriented --skip-already-compared "$1" "$2"
          nvd diff "$1" "$2"
        '';
      })
    ];

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

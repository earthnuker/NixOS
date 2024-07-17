let 
  sources = import ./npins;
in {
  config,
  pkgs,
  stylix,
  nixpkgs,
  ...
}: {
  home = {
    username = "earthnuker";
    homeDirectory = "/home/earthnuker";
    packages = with pkgs; [
      alejandra
      batmon
      btop
      dex
      eza
      ffmpeg
      firefox
      iftop
      iotop
      micromamba
      fastfetch
      pandoc
      rustup
      tmux
      vscode
      betterlockscreen
      eww
      neovide
      tdesktop
      xss-lock
      python3Full
      starship
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "code -n -w";
      ZSH_CACHE_DIR = "/home/earthnuker/.cache/oh-my-zsh";
    };
  };

  xdg.configFile = {
    "awesome" = {
      recursive = true;
      source = ./awesomewm;
    };
  };
  home.file = {
    ".config/awesome/lain".source = pkgs.fetchFromGitHub {
      owner = "lcpz";
      repo = "lain";
      rev = "88f5a8a";
      sha256 = "sha256-MH/aiYfcO3lrcuNbnIu4QHqPq25LwzTprOhEJUJBJ7I=";
    };
    ".config/awesome/layout-machi".source = pkgs.fetchFromGitHub {
      owner = "lcpz";
      repo = "lain";
      rev = "88f5a8a";
      sha256 = "sha256-MH/aiYfcO3lrcuNbnIu4QHqPq25LwzTprOhEJUJBJ7I=";
    };
  };
  services = {
    ssh-agent.enable = true;
  };
  programs = {
    lazygit.enable = true;
    topgrade.enable = true;
    command-not-found.enable = true;
    kitty = {
      enable = true;
      shellIntegration.enableZshIntegration = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
      userName = "earthnuker";
      userEmail = "earthnuker@gmail.com";
      difftastic.enable = true;
      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
      };
    };
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      withNodeJs = true;
      withPython3 = true;
      extraConfig = ''
        :imap jk <Esc>
        :set number
      '';
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      autocd = true;
      history.extended = true;
      initExtra = ''
        export TERM="xterm-256color"
        bindkey -e
        eval $(ssh-agent) > /dev/null
      '';
      antidote = {
        enable = true;
        useFriendlyNames = true;
        plugins = [
          "ohmyzsh/ohmyzsh path:lib/git.zsh"
          "ohmyzsh/ohmyzsh path:lib/clipboard.zsh"
          "ohmyzsh/ohmyzsh path:plugins/aliases"
          "ohmyzsh/ohmyzsh path:plugins/copypath"
          "ohmyzsh/ohmyzsh path:plugins/colored-man-pages"
          "ohmyzsh/ohmyzsh path:plugins/extract"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "ohmyzsh/ohmyzsh path:plugins/git-extras"
          "ohmyzsh/ohmyzsh path:plugins/magic-enter"
          "ohmyzsh/ohmyzsh path:plugins/npm"
          "ohmyzsh/ohmyzsh path:plugins/pyenv"
          "ohmyzsh/ohmyzsh path:plugins/python"
          "ohmyzsh/ohmyzsh path:plugins/tmux"
          "ohmyzsh/ohmyzsh path:plugins/rust"
          "djui/alias-tips"
          "dim-an/cod"
          "wfxr/forgit"
          "MichaelAquilina/zsh-autoswitch-virtualenv"
          "chisui/zsh-nix-shell"
          "nix-community/nix-zsh-completions"
        ];
      };
      shellAliases = {
        "lg" = "lazygit";
        "nxt" = "nh os test -u -a";
        "nxs" = "nh os switch -u -a";
        "nxgc" = "nh clean all -k 10 -K 1w";
        "neofetch" = "fastfetch";
      };
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;
        aws.disabled = true;
        gcloud.disabled = true;
        line_break.disabled = true;
      };
    };
  };

  xsession = {
    enable = true;
    initExtra = ''
      "${pkgs.dex}/bin/dex" -a
    '';
    windowManager.awesome = {
      enable = true;
      noArgb = true;
      package = pkgs.awesome.override {
        lua = pkgs.luajit;
      };
      luaModules = [
        pkgs.luajitPackages.luarocks
      ];
    };
  };
  stylix = {
    enable = false;
    image = ./wallpaper.jpg;
    polarity = "dark";
  };
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}

let
  sources = import ./npins;
in
  {
    config,
    pkgs,
    stylix,
    nixpkgs,
    inputs,
    ...
  }: {
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
        yazi
        rofi
        pavucontrol
        qemu
        networkmanager_dmenu
        nixpacks
        nix-inspect
        vim.xxd
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
        source = ./awesomewm;
      };
    };
    home.file = {
      ".config/awesome/lain".source = sources.lain.outPath;
      ".config/awesome/layout-machi".source = sources."layout-machi".outPath;
    };
    services = {
      ssh-agent.enable = true;
    };
    programs = {
      lazygit.enable = true;
      topgrade.enable = true;
      nix-index.enable = true;
      fd.enable = true;
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      ssh = {
        enable = true;
        addKeysToAgent = "yes";
      };
      kitty = {
        enable = true;
        shellIntegration.enableZshIntegration = true;
      };
      fzf = {
        enable = true;
        enableZshIntegration = true;
      };
      atuin = {
        enable = true;
        enableZshIntegration = true;
      };
      zellij = {
        enable = true;
        enableZshIntegration = false;
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
        enableVteIntegration = true;

        initExtra = ''
          setopt extendedglob
          setopt autocd
          setopt append_history share_history histignorealldups
          bindkey -e
          eval $(ssh-agent) > /dev/null
          zstyle ':completion:*:descriptions' format '[%d]'
          zstyle ':completion:*' rehash true
          zstyle ':completion:*:descriptions' format '[%d]'
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
          zstyle ':fzf-tab:*' switch-group ',' '.'
          autoload -Uz add-zsh-hook

          function reset_broken_terminal () {
            printf '%b' '\e[0m\e(B\e)0\017\e[?5l\e7\e[0;0r\e8'
          }

          add-zsh-hook -Uz precmd reset_broken_terminal

          typeset -g -A key

          key[Home]="''${terminfo[khome]}"
          key[End]="''${terminfo[kend]}"
          key[Insert]="''${terminfo[kich1]}"
          key[Backspace]="''${terminfo[kbs]}"
          key[Delete]="''${terminfo[kdch1]}"
          key[Up]="''${terminfo[kcuu1]}"
          key[Down]="''${terminfo[kcud1]}"
          key[Left]="''${terminfo[kcub1]}"
          key[Right]="''${terminfo[kcuf1]}"
          key[PageUp]="''${terminfo[kpp]}"
          key[PageDown]="''${terminfo[knp]}"
          key[Shift-Tab]="''${terminfo[kcbt]}"

          # setup key accordingly
          [[ -n "''${key[Home]}"      ]] && bindkey -- "''${key[Home]}"       beginning-of-line
          [[ -n "''${key[End]}"       ]] && bindkey -- "''${key[End]}"        end-of-line
          [[ -n "''${key[Insert]}"    ]] && bindkey -- "''${key[Insert]}"     overwrite-mode
          [[ -n "''${key[Backspace]}" ]] && bindkey -- "''${key[Backspace]}"  backward-delete-char
          [[ -n "''${key[Delete]}"    ]] && bindkey -- "''${key[Delete]}"     delete-char
          [[ -n "''${key[Up]}"        ]] && bindkey -- "''${key[Up]}"         up-line-or-history
          [[ -n "''${key[Down]}"      ]] && bindkey -- "''${key[Down]}"       down-line-or-history
          [[ -n "''${key[Left]}"      ]] && bindkey -- "''${key[Left]}"       backward-char
          [[ -n "''${key[Right]}"     ]] && bindkey -- "''${key[Right]}"      forward-char
          [[ -n "''${key[PageUp]}"    ]] && bindkey -- "''${key[PageUp]}"     beginning-of-buffer-or-history
          [[ -n "''${key[PageDown]}"  ]] && bindkey -- "''${key[PageDown]}"   end-of-buffer-or-history
          [[ -n "''${key[Shift-Tab]}" ]] && bindkey -- "''${key[Shift-Tab]}"  reverse-menu-complete

          # Finally, make sure the terminal is in application mode, when zle is
          # active. Only then are the values from ''$terminfo valid.
          if (( ''${+terminfo[smkx]} && ''${+terminfo[rmkx]} )); then
            autoload -Uz add-zle-hook-widget
            function zle_application_mode_start { echoti smkx }
            function zle_application_mode_stop { echoti rmkx }
            add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
            add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
          fi
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
            #"ohmyzsh/ohmyzsh path:plugins/magic-enter"
            "ohmyzsh/ohmyzsh path:plugins/npm"
            "ohmyzsh/ohmyzsh path:plugins/pyenv"
            "ohmyzsh/ohmyzsh path:plugins/python"
            #"ohmyzsh/ohmyzsh path:plugins/tmux"
            "ohmyzsh/ohmyzsh path:plugins/rust"
            "djui/alias-tips"
            "dim-an/cod"
            "wfxr/forgit"
            "MichaelAquilina/zsh-autoswitch-virtualenv"
            "chisui/zsh-nix-shell"
            "nix-community/nix-zsh-completions"
            "Aloxaf/fzf-tab"
          ];
        };
        shellAliases = {
          "lg" = "lazygit";
          "nxt" = "nh os test -u -a -D nixdiff";
          "nxb" = "nh os build -u -a -D nixdiff";
          "nxs" = "nh os switch -u -a -D nixdiff";
          "nxgc" = "nh clean all -k 10 -K 1w; nix-store --optimize";
          "neofetch" = "fastfetch";
        };
      };
      starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          add_newline = true;
          aws.disabled = true;
          gcloud.disabled = true;
          line_break.disabled = true;
          nix_shell = {
            impure_msg = "[impure shell](bold red)";
            pure_msg = "[pure shell](bold green)";
            unknown_msg = "[shell](bold yellow)";
            heuristic = true;
          };
        };
      };
    };

    xsession = {
      enable = true;
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
        enable = true;
        package = pkgs.i3-gaps;
      };
    };
    stylix = {
      enable = false;
      image = ./wallpaper.jpg;
      polarity = "dark";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/pico.yaml";
    };
    home.stateVersion = "24.05";
    programs.home-manager.enable = true;
  }

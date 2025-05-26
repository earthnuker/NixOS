{pkgs, ...}: {
  imports = [
    ./zsh.nix
    ./starship.nix
    ./mpv.nix
    ./discord.nix
  ];
  programs = {
    home-manager.enable = true;
    lazygit.enable = true;
    topgrade.enable = true;
    nix-index.enable = true;
    fd.enable = true;
    zathura = {
      enable = true;
      options = {
        recolor = true;
        adjust-open = "best-fit";
      };
    };
    helix = {
      enable = true;
      package = pkgs.evil-helix;
      defaultEditor = true;
      settings = {
        theme = "stylix";
        editor = {
          true-color = true;
          color-modes = true;
          cursor-shape = {
            normal = "block";
            insert = "bar";
            select = "underline";
          };
          gutters = [
            "diagnostics"
            "line-numbers"
            "spacer"
            "diff"
          ];
          file-picker = {
            hidden = false;
          };
          indent-guides = {
            render = false;
            character = "│";
          };
          lsp = {
            display-messages = true;
          };
          mouse = true;
        };
      };
    };
    eza = {
      enable = true;
      git = true;
      extraOptions = [
        "--group-directories-first"
        "--hyperlink"
        "-sold"
      ];
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    vscode = {
      enable = true;
    };
    ssh = {
      enable = true;
      addKeysToAgent = "yes";
      forwardAgent = true;
      matchBlocks = {
        talos = {
          user = "root";
        };
      };
    };
    kitty = {
      enable = true;
      shellIntegration.enableZshIntegration = true;
      shellIntegration.enableFishIntegration = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
    atuin = {
      enable = false;
      enableZshIntegration = true;
      enableFishIntegration = true;
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
      difftastic = {
        enable = true;
        display = "inline";
        background = "dark";
      };
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
      plugins = with pkgs.vimPlugins; [
        nvim-treesitter.withAllGrammars
        vim-nix
      ];
    };
    nushell = {
      enable = true;
    };
    fish = {
      enable = true;
      plugins = [
        {
          name = "grc";
          inherit (pkgs.fishPlugins.grc) src;
        }
      ];
    };
  };
}

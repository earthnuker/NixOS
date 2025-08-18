{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./zsh.nix
    ./starship.nix
    ./mpv.nix
    ./discord
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
    helix = import ./helix.nix {inherit lib pkgs;};
    lsd = {
      enable = true;
      settings = {
        indicators = true;
        sorting = {
          column = "time";
          reverse = true;
        };
        hyperlink = "auto";
        header = false;
      };
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
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          addKeysToAgent = "yes";
          forwardAgent = true;
        };
        talos = {
          user = "root";
        };
      };
    };
    wezterm = {
      enable = true;
      enableZshIntegration = true;
      extraConfig = lib.readFile ./wezterm.lua;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
    bat = {
      enable = true;
      extraPackages = with pkgs; [
        bat-extras.core
      ];
      config = {
        style = "plain";
        paging = "auto";
      };
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

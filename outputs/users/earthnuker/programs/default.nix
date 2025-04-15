{pkgs, ...}: {
  programs = {
    home-manager.enable = true;
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
          src = pkgs.fishPlugins.grc.src;
        }
      ];
    };
    zsh = import ./zsh.nix;
    starship = import ./starship.nix;
  };
}

{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    clock24 = true;
    newSession = true;
    prefix = "C-a";
  };
  programs.zsh = {
    enable = true;
    localVariables = {
      "ZSH_TMUX_AUTOSTART" = "true";
      "ZSH_TMUX_AUTOQUIT" = "true";
      "ZSH_TMUX_AUTOCONNECT" = "true";
    };
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
        "ohmyzsh/ohmyzsh path:plugins/tmux"
        "Aloxaf/fzf-tab"
      ];
    };
  };
  home = {
    stateVersion = "24.05";
    username = "coolbug";
    enableNixpkgsReleaseCheck = false;
    shell.enableZshIntegration = true;
    packages = with pkgs; [
      nano
      (weechat.override
        {
          configure = {availablePlugins, ...}: {
            plugins = builtins.attrValues (
              availablePlugins
              // {
                python = availablePlugins.python.withPackages (ps: with ps; [requests]);
              }
            );
            scripts = with pkgs.weechatScripts; [
              weechat-grep
              highmon
              colorize_nicks
              autosort
              weechat-go
              url_hint
            ];
          };
        })
    ];
    sessionVariables = {
      EDITOR = "nano";
      ZSH_CACHE_DIR = "/home/coolbug/.cache/oh-my-zsh";
      NSEARCH_FZF_CMD = "fzf --multi";
    };
  };
  services = {
    ssh-agent.enable = true;
  };
}

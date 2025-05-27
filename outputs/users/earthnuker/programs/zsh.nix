{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    autocd = true;
    history.extended = true;
    enableVteIntegration = true;

    initContent = ''
      unsetopt extendedGlob
      setopt autocd
      setopt append_history share_history histignorealldups
      setopt interactive_comments
      bindkey -e
      #eval $(ssh-agent) > /dev/null
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
      "neofetch" = "fastfetch";
      "cp+" = "rsync -ah --progress";
      "sys" = "~/nixos/sys";
    };
  };
}

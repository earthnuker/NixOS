{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./programs
    ./packages.nix
  ];
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };
  # xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;
  home = {
    stateVersion = "24.05";
    username = "earthnuker";
    homeDirectory = "/home/earthnuker";
    enableNixpkgsReleaseCheck = false;
    shell.enableFishIntegration = true;
    sessionVariables = {
      EDITOR = lib.mkForce "hx";
      ZSH_CACHE_DIR = "/home/earthnuker/.cache/oh-my-zsh";
      TERM = "wezterm";
      TERMINAL = "wezterm";
      DIRENV_WARN_TIMEOUT = 0;
    };
  };

  services = {
    ssh-agent.enable = true;
  };
  stylix.enableReleaseChecks = false;
  xsession = {
    enable = true;
    initExtra = ''
      "${pkgs.dex}/bin/dex" -a
    '';
  };
}

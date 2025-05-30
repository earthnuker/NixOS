{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      git
      htop
      neovim
      wget
      ripgrep
      direnv
      zoxide
      ncdu
      file
      linuxPackages.acpi_call
      sbctl
      iw
      dive
      docker-compose
      tpm2-tss
      greetd.tuigreet
      # Nix
      # home-manager
      npins
      nix-output-monitor
      nix-prefetch
      nix-prefetch-git
      nix-prefetch-github
      nixd
      nil
      nix-zsh-completions
      nurl
      statix
      deadnix
      # nix-web
      nix-tree
      molly-guard
    ];
    variables = {
      EDITOR = "hx";
    };
    localBinInPath = true;
    pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
      "/libexec"
    ];
  };
}

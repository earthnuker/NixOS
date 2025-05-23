{
  inputs,
  pkgs,
  host-config,
  ...
}: let
  nixdiff = pkgs.writeShellApplication {
    name = "nixdiff";
    runtimeInputs = [pkgs.nvd pkgs.nix-diff];
    text = ''
      set -euxo pipefail
      nix-diff --word-oriented --skip-already-compared "$1" "$2"
      nvd diff "$1" "$2"
    '';
  };
  my_pkgs = with pkgs; [
    alejandra
    batmon
    btop
    dex
    eza
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
    python3Full
    starship
    qemu
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
    bat
    cachix
    weechat
    inputs.nsearch.packages.${pkgs.system}.default
    nixdiff
    ffmpeg_7-full
  ];
  x_pkgs = with pkgs; [
    dconf
    firefox
    vscode
    i3lock-fancy
    eww
    neovide
    tdesktop
    xss-lock
    pavucontrol
    networkmanager_dmenu
  ];
in {
  home.packages =
    my_pkgs
    ++ (
      if host-config.services.xserver.enable
      then x_pkgs
      else []
    );
}

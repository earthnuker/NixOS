{
  pkgs,
  host-config,
  ...
}: let
  nixdiff = pkgs.writeShellApplication {
    name = "nixdiff";
    runtimeInputs = [
      pkgs.nvd
      pkgs.nix-diff
    ];
    text = ''
      set -euxo pipefail
      nix-diff --word-oriented --skip-already-compared "$1" "$2"
      nvd diff "$1" "$2"
    '';
  };
  my_pkgs = with pkgs; [
    batmon
    btop
    dex
    iftop
    iotop
    fastfetch
    pandoc
    rustup
    cargo-binstall
    cargo-update
    zellij
    tmux
    python3
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
    nixdiff
    ffmpeg_7-full
    uutils-coreutils-noprefix
  ];
  x_pkgs = with pkgs; [
    dconf
    firefox
    vscode
    eww
    telegram-desktop
    pavucontrol
    # discord
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

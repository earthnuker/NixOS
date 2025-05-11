{
  inputs,
  pkgs,
}:
with pkgs; [
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
  cargo-update
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
  rofi
  pavucontrol
  qemu
  networkmanager_dmenu
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
  (writeShellApplication {
    name = "nixdiff";
    runtimeInputs = [nvd nix-diff];
    text = ''
      set -euxo pipefail
      nix-diff --word-oriented --skip-already-compared "$1" "$2"
      nvd diff "$1" "$2"
    '';
  })
]

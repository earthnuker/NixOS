{pkgs, ...}: let
  plugins = ["grc" "colored-man-pages" "autopair" "done" "fifc"];
  pkg = name: pkgs.fishPlugins."${name}";
  plug = name: {
    inherit name;
    inherit (pkgs.fishPlugins."${name}") src;
  };
in {
  home.packages = map pkg plugins;
  programs.fish = {
    enable = true;
    plugins = map plug plugins;
    interactiveShellInit = ''
      set fish_greeting
      set -Ux fifc_editor hx
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
    '';
    shellAliases = {
      "lg" = "lazygit";
      "neofetch" = "fastfetch";
      "catp" = "bat";
      "cat" = "bat -pp";
      "fd" = "noglob fd";
      "cp+" = "rsync -ah --progress";
      "sys" = "~/nixos/sys";
    };
  };
}

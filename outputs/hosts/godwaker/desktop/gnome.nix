{
  pkgs,
  # lib,
  ...
}: {
  nixpkgs.overlays = [
    # GNOME 46: triple-buffering-v4-46
    # (_final: prev: {
    #   mutter = prev.mutter.overrideAttrs (_old: {
    #     src = pkgs.fetchFromGitLab {
    #       domain = "gitlab.gnome.org";
    #       owner = "vanvugt";
    #       repo = "mutter";
    #       rev = "triple-buffering-v4-47";
    #       hash = "sha256-6n5HSbocU8QDwuhBvhRuvkUE4NflUiUKE0QQ5DJEzwI=";
    #     };
    #   });
    # })
  ];
  programs.dconf.enable = true;
  environment.systemPackages =
    (with pkgs; [
      adwaita-icon-theme
      gnome-settings-daemon
      gnome2.GConf
    ])
    ++ (with pkgs.gnomeExtensions; [
      blur-my-shell
      pop-shell
      appindicator
    ]);
  services = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
}

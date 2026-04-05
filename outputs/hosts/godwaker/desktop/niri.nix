{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    brightnessctl
    fuzzel
    playerctl
    swaylock
  ];
  services.power-profiles-daemon.enable = true;
  programs = {
    ssh.startAgent = lib.mkForce false;
    niri.enable = true;
    noctalia = {
      enable = true;
      recommendedServices.enable = true;
      systemd.enable = true;
    };
    noctalia-greeter = {
      enable = true;
      settings = {
        cursor = {
          theme = "Bibata-Modern-Ice";
          size = 24;
          path = "${pkgs.bibata-cursors}/share/icons";
        };
      };
    };
  };
}

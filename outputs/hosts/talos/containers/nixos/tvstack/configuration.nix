{
  lib,
  # config',
  pkgs,
  ...
}: {
  imports = [
    ./pia.nix
    ./rtorrent.nix
  ];
  boot.isContainer = true;
  services = {
    # sonarr.enable = true;
    # radarr.enable = true;
    # lidarr.enable = true;
    # bazarr.enable = true;
    # prowlarr.enable = true;
    # recyclarr.enable = true;
  };

  pia = {
    region = "de frankfurt"; # <- change me
    transport = "udp"; # "udp" or "tcp"
    tier = "strong"; # "default" or "strong"
    autoStart = true; # start at boot if you want
  };

  environment.systemPackages = with pkgs; [
    cacert
  ];

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };
  services.resolved.enable = true;
  system.stateVersion = "24.05";
}

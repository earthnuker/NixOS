{
  lib,
  config',
  pkgs,
  ...
}: {
  boot.isContainer = true;
  services = {
    # sonarr.enable = true;
    # radarr.enable = true;
    # lidarr.enable = true;
    # bazarr.enable = true;
    # prowlarr.enable = true;
    # recyclarr.enable = true;
  };
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };
  services.pia-vpn = {
    enable = false;
    portForward.enable = true;
    environmentFile = config'.sops.secrets.pia_env.path;
    networkConfig = lib.readFile ./pia.conf;
    certificateFile = pkgs.fetchurl {
      url = "https://www.privateinternetaccess.com/openvpn/ca.rsa.4096.crt";
      sha256 = "1av6dilvm696h7pb5xn91ibw0mrziqsnwk51y8a7da9y8g8v3s9j";
    };
  };
  services.resolved.enable = true;
  system.stateVersion = "24.05";
}

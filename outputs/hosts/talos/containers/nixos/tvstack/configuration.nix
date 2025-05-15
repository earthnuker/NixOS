{lib, ...}: {
  imports = [
    # inputs'.nix-topology.nixosModules.default
  ];
  boot.isContainer = true;
  services = {
    sonarr.enable = true;
    radarr.enable = true;
    lidarr.enable = true;
    bazarr.enable = true;
    prowlarr.enable = true;
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
  services.resolved.enable = true;
  system.stateVersion = "24.05";
}

{pkgs, ...}: {
  wsl = {
    defaultUser = "wsl";
    enable = true;
    startMenuLaunchers = true;
  };
  virtualisation.docker = {
    enable = true;
  };
  networking = {
    hostName = "helios";
    firewall.enable = false;
    networkmanager = {
      enable = true;
    };
  };
  environment.systemPackages = with pkgs; [
    wget
    helix
  ];
  programs.nix-ld = {
    enable = true;
  };
  system.stateVersion = "24.05";
}

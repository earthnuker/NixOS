inputs: {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = import ./oci;
  };
  virtualisation.arion = {
    backend = "docker";
    projects.tvstack.settings = import ./arion/tvstack.nix inputs;
  };
  networking.firewall.allowedTCPPorts = [
    13100
    13101
    13102
  ];
}

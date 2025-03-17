{
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      # ghidra = import ./ghidra.nix;
      test = import ./test.nix;
      linkding = import ./linkding.nix;
      n8n = import ./n8n.nix;
      # homeassistant = import ./homeassistant.nix;
      # nginx-proxy-manager = import ./nginx-proxy-manager.nix;
    };
  };
  virtualisation.arion = {
    backend = "docker";
    projects.test = {
      settings = {
        imports = [
          ./arion/test.nix
        ];
      };
    };
  };
  networking.firewall.allowedTCPPorts = [
    13100
    13101
    13102
  ];
}

inputs: {
  containers = {};
  virtualisation = {
    containers.enable = true;
    oci-containers = {
      backend = "podman";
      containers = import ./oci inputs;
    };
    # quadlet = import ./quadlet inputs;
    podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    13100
    13101
    13102 # Ghidra
  ];
}

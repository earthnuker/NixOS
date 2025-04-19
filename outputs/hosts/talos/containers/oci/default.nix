inputs: {
  virtualisation = {
    containers.enable = true;
    oci-containers = {
      backend = "podman";
      containers = {
        watchtower = import ./watchtower.nix inputs;
        # ghidra-server = import ./ghidra/server.nix inputs;
        # ghidra-tailscale = import ./ghidra/tailscale.nix inputs;
        # tailscale = import ./tailscale.nix;
        # linkding = import ./linkding.nix;
        # n8n = import ./n8n.nix;
      };
    };
  };
}

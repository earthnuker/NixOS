{
  virtualisation = {
    containers.enable = true;
    oci-containers = {
      backend = "podman";
      containers = {
        silverbullet = import ./silverbullet.nix;
        # watchtower = import ./watchtower.nix inputs;
        # p110-exporter = import ./p110-exporter.nix inputs;
        # tailscale = import ./tailscale.nix;
        # linkding = import ./linkding.nix;
        # n8n = import ./n8n.nix;
      };
    };
  };
}

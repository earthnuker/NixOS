{...} @ inputs: {
  virtualisation.arion = {
    backend = "podman-socket";
    # projects.tvstack.settings = import ./tvstack.nix inputs;
    projects.ghidra.settings = import ./ghidra.nix inputs;
  };
}

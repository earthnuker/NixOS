{
  imports = [
    ./tvstack.nix
  ];
  virtualisation.arion = {
    backend = "podman-socket";
    # projects.tvstack.settings = import ./tvstack.nix inputs;
  };
}

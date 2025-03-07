{
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      ghidra = import ./ghidra.nix;
      test = import ./test.nix;
    };
  };
}

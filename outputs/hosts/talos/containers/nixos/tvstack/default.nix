{inputs, ...} @ flake_inputs: {
  containers = {
    tvstack = {
      inherit (inputs) nixpkgs;
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.20";
      localAddress = "192.168.100.21";
      additionalCapabilities = ["CAP_NET_ADMIN"];
      specialArgs = {
        config' = flake_inputs.config;
        inputs' = flake_inputs.inputs;
      };
      config = {
        imports = [
          ./configuration.nix
          inputs.nix-topology.nixosModules.default
          inputs.nix-pia-vpn.nixosModules.default
        ];
      };
    };
  };
}

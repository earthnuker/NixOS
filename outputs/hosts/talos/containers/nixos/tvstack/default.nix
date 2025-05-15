flake_inputs: {
  containers = {
    tvstack = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.11";
      additionalCapabilities = ["CAP_NET_ADMIN"];
      config = {...}: {
        extraSpecialArgs = {
          config' = flake_inputs.config;
          inputs' = flake_inputs.inputs;
        };
        imports = [
          ./configuration.nix
        ];
      };
    };
  };
}

{inputs, ...} @ flake_inputs: let
  config' = flake_inputs.config;
  inputs' = flake_inputs.inputs;
in {
  sops.secrets = {
    radarr_api_key.restartUnits = [
      "recyclarr.service"
    ];
    sonarr_api_key.restartUnits = [
      "recyclarr.service"
    ];
  };
  containers = {
    tvstack = {
      inherit (inputs) nixpkgs;
      autoStart = true;
      privateNetwork = true;
      enableTun = true;
      hostAddress = "192.168.100.20";
      localAddress = "192.168.100.21";
      specialArgs = {
        inherit config' inputs';
      };
      bindMounts = {
        "${config'.sops.secrets.pia_auth.path}" = {
          isReadOnly = true;
        };
        "/mnt/data/media/torrents/" = {
          isReadOnly = false;
        };
      };
      config = {
        imports = [
          ./configuration.nix
          inputs.nix-topology.nixosModules.default
        ];
      };
    };
  };
}

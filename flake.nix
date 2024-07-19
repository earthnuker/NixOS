{
  description = "Godwaker system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    nur = {
      url = "github:nix-community/NUR";
    };
  };

  outputs = {
    nixpkgs,
    nixos-hardware,
    stylix,
    nur,
    ...
  } @ inputs: {
    nixosConfigurations.godwaker = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        ./configuration.nix
        nixos-hardware.nixosModules.lenovo-thinkpad-t470s
        stylix.nixosModules.stylix
        nur.nixosModules.nur
      ];
    };
  };
}

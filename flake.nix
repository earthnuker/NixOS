{
  description = "Godwaker system configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    stylix,
    lanzaboote,
    ...
  } @ inputs: {
    nixosConfigurations.godwaker = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs nixpkgs;};
      modules = [
        (_: {
          system.configurationRevision =
            if self ? rev
            then self.rev
            else throw "Refusing to build from a dirty Git tree!";
        })
        ./configuration.nix
        nixos-hardware.nixosModules.lenovo-thinkpad-t470s
        stylix.nixosModules.stylix
        lanzaboote.nixosModules.lanzaboote
      ];
    };
  };
}

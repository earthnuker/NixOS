{
  description = "Godwaker system configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable-small";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nsearch = {
      url = "github:niksingh710/nsearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    stylix,
    lanzaboote,
    ...
  } @ inputs: let
    system = "x86_64-linux";
  in {
    formatter."${system}" = nixpkgs.legacyPackages.${system}.alejandra;
    nixosConfigurations.godwaker = nixpkgs.lib.nixosSystem {
      system = system;
      specialArgs = {
        inherit inputs nixpkgs;
        revision =
          if self.sourceInfo ? dirtyShortRev
          then self.sourceInfo.dirtyShortRev
          else self.sourceInfo.shortRev or "dirty";
      };
      modules = [
        ./configuration.nix
        nixos-hardware.nixosModules.lenovo-thinkpad-t470s
        stylix.nixosModules.stylix
        lanzaboote.nixosModules.lanzaboote
      ];
    };
  };
}

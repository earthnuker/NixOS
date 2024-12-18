{
  description = "Godwaker system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
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
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    stylix,
    lanzaboote,
    lix-module,
    nix-index-database,
    ...
  } @ inputs: let
    system = "x86_64-linux";
  in {
    formatter."${system}" = nixpkgs.legacyPackages.${system}.alejandra;
    nixosConfigurations.godwaker = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs nixpkgs;
      };
      modules = [
        ./revision.nix
        ./configuration.nix
        nixos-hardware.nixosModules.lenovo-thinkpad-t470s
        nixos-hardware.nixosModules.common-pc-laptop-ssd
        stylix.nixosModules.stylix
        lanzaboote.nixosModules.lanzaboote
        # lix-module.nixosModules.default
        nix-index-database.nixosModules.nix-index
        {
          programs.nix-index-database.comma.enable = true;
          nixpkgs.overlays = [
            (self: super: {
              utillinux = super.util-linux;
            })
          ];
        }
      ];
    };
  };
}

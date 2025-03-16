{
  description = "LocalNet system configuration";
  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    stylix,
    lanzaboote,
    lix-module,
    determinate,
    nix-index-database,
    agenix,
    disko,
    srvos,
    deploy-rs,
    nixos-facter-modules,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    users = {
      earthnuker = import ./users/earthnuker;
    };
    sources = import ./npins;
    root = ./.;
  in {
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;
    apps."${system}".default = {
      type = "app";
      program = "${inputs.deploy-rs.defaultPackage.${system}}/bin/deploy";
      meta = {
        description = "Run deployment";
      };
    };
    deploy.nodes = {
      talos = {
        hostname = "talos.lan";
        sshUser = "root";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.talos;
        };
      };
    };
    nixosConfigurations = {
      talos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs nixpkgs;
          drives = {
            system = "nvme-VMware_Virtual_NVMe_Disk_VMware_NVME_0000";
            storage = [
              "wwn-0x5000c29c72d5ee1a"
              "wwn-0x5000c29aff2e66b9"
              "wwn-0x5000c294334516a8"
            ];
          };
        };
        modules = [
          ./hosts/talos
          disko.nixosModules.disko
          srvos.nixosModules.server
          srvos.nixosModules.mixins-terminfo
          srvos.nixosModules.mixins-systemd-boot
          nixos-facter-modules.nixosModules.facter
          agenix.nixosModules.default
        ];
      };
      godwaker = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs nixpkgs users sources root;
        };
        modules = [
          ./revision.nix
          ./hosts/godwaker
          nixos-hardware.nixosModules.lenovo-thinkpad-t470s
          nixos-hardware.nixosModules.common-pc-laptop-ssd
          stylix.nixosModules.stylix
          lanzaboote.nixosModules.lanzaboote
          # lix-module.nixosModules.default
          determinate.nixosModules.default
          agenix.nixosModules.default
          nix-index-database.nixosModules.nix-index
        ];
      };
    };
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ssh-keys-earthnuker = {
      url = "https://github.com/earthnuker.keys";
      flake = false;
    };
  };
}

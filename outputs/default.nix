{
  self,
  authentik-nix,
  deploy-rs,
  disko,
  flake-utils,
  lanzaboote,
  lix-module,
  nix-index-database,
  nix-topology,
  nixos-facter-modules,
  nixos-hardware,
  home-manager,
  nixpkgs,
  quadlet,
  sops-nix,
  srvos,
  stylix,
  ...
} @ inputs: let
  vars = import ./../vars;
  system = "x86_64-linux";
  users = {
    earthnuker = import ./users/earthnuker;
  };
  sources = import ../npins;
  pkgs = import nixpkgs {
    inherit system;
    overlays = [nix-topology.overlays.default];
  };
  root = ./..;
  secrets = secrets: {
    sops = {
      defaultSopsFile = "${self}/secrets.yml";
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      secrets = builtins.listToAttrs (map (name: {
          inherit name;
          value = {};
        })
        secrets);
    };
  };
in rec {
  formatter.${system} = pkgs.alejandra;
  apps."${system}".default = {
    type = "app";
    program = "${deploy-rs.defaultPackage.${system}}/bin/deploy";
    meta = {
      description = "Run deployment";
    };
  };
  deploy.nodes = {
    talos = rec {
      hostname = "talos.lan";
      sshUser = "root";
      fastConnection = true;
      remoteBuild = true;
      profiles.system = {
        user = sshUser;
        path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.talos;
      };
    };
  };
  iso = nixosConfigurations.iso.config.system.build.isoImage;

  topology = import nix-topology {
    inherit pkgs;
    modules = [
      ./topology
      {inherit (self) nixosConfigurations;}
    ];
  };

  nixosConfigurations = {
    iso = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs nixpkgs;
      };
      modules = [
        ./installer
        nix-topology.nixosModules.default
        {
          users.users.root = {
            openssh.authorizedKeys.keyFiles = [
              inputs.ssh-keys-earthnuker.outPath
            ];
          };
        }
        ({modulesPath, ...}: {
          imports = [
            (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
            (modulesPath + "/installer/cd-dvd/channel.nix")
          ];
        })
      ];
    };

    talos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs nixpkgs;
        drives = vars.talos.drives;
      };
      modules = [
        ./hosts/talos
        disko.nixosModules.disko
        srvos.nixosModules.server
        srvos.nixosModules.mixins-terminfo
        srvos.nixosModules.mixins-systemd-boot
        nixos-facter-modules.nixosModules.facter
        quadlet.nixosModules.quadlet
        sops-nix.nixosModules.sops
        nix-topology.nixosModules.default
        authentik-nix.nixosModules.default
        (secrets vars.talos.secrets)
      ];
    };
    godwaker = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs nixpkgs users sources root;
        drives = {
          system = "nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX2J805949_1";
        };
      };
      modules = [
        ./util/revision.nix
        ./hosts/godwaker
        disko.nixosModules.disko
        nixos-hardware.nixosModules.lenovo-thinkpad-t470s
        nixos-hardware.nixosModules.common-pc-laptop-ssd
        home-manager.nixosModules.home-manager
        stylix.nixosModules.stylix
        lanzaboote.nixosModules.lanzaboote
        #lix-module.nixosModules.default
        nix-index-database.nixosModules.nix-index
        sops-nix.nixosModules.sops
        nix-topology.nixosModules.default
      ];
    };
  };
}

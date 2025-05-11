{
  self,
  arion,
  authentik-nix,
  deploy-rs,
  disko,
  lanzaboote,
  nix-index-database,
  nix-topology,
  nixos-facter-modules,
  nixos-hardware,
  home-manager,
  nixpkgs,
  ucodenix,
  sops-nix,
  srvos,
  stylix,
  devshell,
  git-hooks,
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
    overlays = [
      nix-topology.overlays.default
      devshell.overlays.default
    ];
  };
  inherit (pkgs) lib;
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
  imports = [
    ./imp_test.nix
  ];
  formatter.${system} = pkgs.alejandra;
  apps."${system}".default = {
    type = "app";
    program = "${lib.getExe deploy-rs.defaultPackage.${system}}";
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
  iso = nixosConfigurations.installer.config.system.build.isoImage;

  topology = import nix-topology {
    inherit pkgs;
    modules = [
      ./topology
      {inherit (self) nixosConfigurations;}
    ];
  };

  checks.${system}.git-hooks = git-hooks.lib.${system}.run {
    src = nixpkgs.lib.cleanSource root;
    hooks = {
      # Nix
      alejandra.enable = true;
      deadnix.enable = true;
      statix.enable = true;
      flake-checker.enable = true;
    };
  };

  devShells.${system}.default = pkgs.devshell.mkShell {
    name = "Hive";
    packages = with pkgs; [
      just
      zsh
      nh
      git
      jq
      sshpass
      deploy-rs
      ssh-to-age
      watchexec
      sops
      yq-go
      curl
    ];
    commands = [
      {
        package = pkgs.alejandra;
        category = "formatters";
      }
      {
        package = pkgs.deadnix;
        category = "linters";
      }
      {
        package = pkgs.statix;
        category = "linters";
      }
      {
        package = deploy-rs.defaultPackage.${system};
        category = "tools";
      }
      {
        package = pkgs.sops;
        category = "tools";
      }
      {
        package = pkgs.ssh-to-age;
        category = "tools";
      }
      {
        package = pkgs.yq-go;
        category = "tools";
      }
      {
        package = "just";
        category = "tools";
      }
    ];
    devshell.startup.git-hooks.text = self.checks.${system}.git-hooks.shellHook;
  };

  nixosConfigurations = {
    installer = nixpkgs.lib.nixosSystem {
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
        inherit (vars.talos) drives;
      };
      modules = [
        ./util/revision.nix
        ./hosts/talos
        disko.nixosModules.disko
        srvos.nixosModules.server
        srvos.nixosModules.mixins-terminfo
        srvos.nixosModules.mixins-systemd-boot
        nixos-facter-modules.nixosModules.facter
        # quadlet.nixosModules.quadlet
        nix-index-database.nixosModules.nix-index
        arion.nixosModules.arion
        sops-nix.nixosModules.sops
        nix-topology.nixosModules.default
        authentik-nix.nixosModules.default
        ucodenix.nixosModules.default
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
        nix-index-database.nixosModules.nix-index
        sops-nix.nixosModules.sops
        nix-topology.nixosModules.default
        ucodenix.nixosModules.default
      ];
    };
  };
}

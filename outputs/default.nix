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
  vars = import ./../vars (
    inputs
    // {
      inherit pkgs;
      inherit (pkgs) lib;
    }
  );
in rec {
  formatter.${system} = pkgs.alejandra;
  apps."${system}" = {
    deploy = let
      deploy = lib.getExe deploy-rs.defaultPackage.${system};
      nom = lib.getExe pkgs.nix-output-monitor;
      script = pkgs.writeShellScriptBin "deploy" ''
        #!/usr/bin/env bash
        set -exuo pipefail
        ${deploy} $@ -- . --log-format internal-json |& ${nom} --json
      '';
    in {
      type = "app";
      program = "${lib.getExe script}";
      meta = {
        description = "Run deployment";
      };
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
  packages."${system}" = {
    installer-iso = nixosConfigurations.installer.config.system.build.isoImage;
    sd-image = nixosConfigurations.daedalus.config.system.build.sdImage;
    # diagram =
    #   (import nix-topology
    #     {
    #       inherit pkgs;
    #       modules = [
    #         ./topology
    #         {inherit (self) nixosConfigurations;}
    #       ];
    #     }).config.output;
  };

  # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  checks.${system} =
    {
      git-hooks = git-hooks.lib.${system}.run {
        src = nixpkgs.lib.cleanSource root;
        addGcRoot = true;
        hooks = {
          alejandra.enable = true;
          deadnix.enable = true;
          statix.enable = true;
          ripsecrets.enable = true;
          flake-checker.enable = true;
          check-case-conflicts.enable = true;
          check-executables-have-shebangs.enable = true;
          check-merge-conflicts.enable = true;
          check-shebang-scripts-are-executable.enable = true;
          check-symlinks.enable = true;
          lychee = {
            enable = true;
            types = ["markdown"];
            settings.flags = "--cache --verbose";
          };
          markdownlint = {
            enable = true;
            settings.configuration.MD013 = false;
          };
        };
      };
    }
    // (inputs.deploy-rs.lib.${system}.deployChecks self.deploy);

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
    # devshell.startup.git-hooks.text = self.checks.${system}.git-hooks.shellHook;
  };

  # The installer ISO configuration.
  nixosConfigurations = {
    # This is the installer ISO configuration.
    installer = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs nixpkgs;
        vars = vars.installer;
      };
      modules = [
        ./installer
        nix-topology.nixosModules.default
      ];
    };

    # This is the main system configuration for the Talos server.
    talos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs nixpkgs;
        vars = vars.talos;
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

    daedalus = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        inherit inputs nixpkgs;
        vars = vars.daedalus;
      };
      modules = [
        ./hosts/daedalus
        nix-topology.nixosModules.default
      ];
    };

    # This is the main system configuration for the Godwaker laptop.
    godwaker = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs nixpkgs users sources root;
        vars = vars.godwaker;
      };
      modules = [
        ./util/revision.nix
        ./hosts/godwaker
        disko.nixosModules.disko
        nixos-facter-modules.nixosModules.facter
        nixos-hardware.nixosModules.lenovo-thinkpad-t470s
        nixos-hardware.nixosModules.common-pc-laptop-ssd
        home-manager.nixosModules.home-manager
        stylix.nixosModules.stylix
        lanzaboote.nixosModules.lanzaboote
        nix-index-database.nixosModules.nix-index
        sops-nix.nixosModules.sops
        nix-topology.nixosModules.default
        ucodenix.nixosModules.default
        (secrets vars.godwaker.secrets)
      ];
    };
  };
}

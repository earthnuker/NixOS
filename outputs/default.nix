{
  self,
  nixpkgs,
  ...
} @ inputs: let
  system = "x86_64-linux";
  users = {
    earthnuker = import ./users/earthnuker {
      inherit
        inputs
        root
        sources
        pkgs
        ;
    };
  };
  sources = import ../npins;
  pkgs = import nixpkgs {
    inherit system;
    overlays = [
      inputs.nix-topology.overlays.default
      inputs.devshell.overlays.default
    ];
  };
  inherit (pkgs) lib;
  root = ./..;
  secrets = secrets: {
    sops = {
      defaultSopsFile = "${self}/secrets.yml";
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      secrets = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = {};
        })
        secrets
      );
    };
  };
  vars = import "${root}/vars" (
    inputs
    // {
      inherit pkgs;
      inherit (pkgs) lib;
    }
  );
in rec {
  formatter.${system} = pkgs.alejandra;
  apps."${system}" = {
    wsl = let
      wsl-builder = nixosConfigurations.helios.config.system.build.tarballBuilder;
      script = pkgs.writeShellScriptBin "wsl" ''
        #!/usr/bin/env bash
        set -exuo pipefail
        sudo ${lib.getExe wsl-builder}
      '';
    in {
      type = "app";
      program = "${lib.getExe script}";
      meta = {
        description = "build WSL tarball";
      };
    };
    deploy = let
      deploy = lib.getExe inputs.deploy-rs.packages.${system}.default;
      nom = lib.getExe pkgs.nix-output-monitor;
      script = pkgs.writeShellScriptBin "deploy" ''
        #!/usr/bin/env bash
        set -exuo pipefail
        ${deploy} $@ -- . -j auto -v --log-format internal-json |& ${nom} --json
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
        path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.talos;
      };
    };
  };
  packages."${system}" = {
    installer-iso = nixosConfigurations.installer.config.system.build.isoImage;
    sd-image = nixosConfigurations.daedalus.config.system.build.sdImage;
    diagram = let
      # Gross hack
      topology = import inputs.nix-topology {
        inherit pkgs;
        modules = [
          ./topology
          {inherit (self) nixosConfigurations;}
        ];
      };
    in
      pkgs.runCommandNoCC "topology" {} ''
        set +xeuo pipefail
        cp -R ${topology.config.output}/ $out
      '';
  };

  # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  checks.${system} =
    {
      git-hooks = inputs.git-hooks.lib.${system}.run {
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
        package = inputs.deploy-rs.packages.${system}.default;
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
        inputs.nix-topology.nixosModules.default
      ];
    };

    helios = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs nixpkgs;
        vars = vars.helios or {};
      };
      modules = [
        ./hosts/helios
        inputs.nix-topology.nixosModules.default
        inputs.nixos-wsl.nixosModules.default
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
        inputs.disko.nixosModules.disko
        inputs.srvos.nixosModules.server
        inputs.srvos.nixosModules.mixins-terminfo
        inputs.srvos.nixosModules.mixins-systemd-boot
        inputs.nixos-facter-modules.nixosModules.facter
        # quadlet.nixosModules.quadlet
        inputs.nix-index-database.nixosModules.nix-index
        inputs.arion.nixosModules.arion
        inputs.sops-nix.nixosModules.sops
        inputs.nix-topology.nixosModules.default
        inputs.authentik-nix.nixosModules.default
        inputs.ucodenix.nixosModules.default
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
        inputs.nix-topology.nixosModules.default
      ];
    };

    # This is the main system configuration for the Godwaker laptop.
    godwaker = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          inputs
          nixpkgs
          users
          sources
          root
          ;
        vars = vars.godwaker;
      };
      modules = [
        ./util/revision.nix
        ./hosts/godwaker
        inputs.disko.nixosModules.disko
        inputs.nixos-facter-modules.nixosModules.facter
        inputs.home-manager.nixosModules.home-manager
        inputs.stylix.nixosModules.stylix
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.nix-index-database.nixosModules.nix-index
        inputs.sops-nix.nixosModules.sops
        inputs.nix-topology.nixosModules.default
        inputs.ucodenix.nixosModules.default
        (secrets vars.godwaker.secrets)
      ];
    };
  };
}

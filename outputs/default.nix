{
  self,
  nixpkgs,
  ...
} @ inputs: let
  system = "x86_64-linux";
  users = {
    earthnuker = ./users/earthnuker;
    coolbug = ./users/coolbug;
  };
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
      secrets =
        builtins.listToAttrs (
          map (name: {
            inherit name;
            value = {};
          })
          secrets
        )
        // {
          lldap_user_pass = {
            mode = "0400";
            owner = "lldap";
            group = "lldap";
          };
        };
    };
  };
  vars = import "${root}/vars" (
    inputs
    // {
      inherit pkgs;
      inherit (pkgs) lib;
    }
  );
  /*
  Talos (NAS):
    ./util/revision.nix
    ./hosts/talos
    ../modules/common
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
    inputs.home-manager.nixosModules.home-manager
  Godwaker (Thinkpad T470):
      ./util/revision.nix
    ./hosts/godwaker
    ../modules/common
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
  Daedalus (ODROID):
    ./hosts/daedalus
    ../modules/common
    inputs.nix-topology.nixosModules.default
  Helios (WSL):
    ./hosts/helios
    ../modules/common
    inputs.nix-topology.nixosModules.default
    inputs.nixos-wsl.nixosModules.default
  */
  roles = let roles = {
    "common" = [
      ../modules/common
      inputs.nix-topology.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.nixos-facter-modules.nixosModules.facter
    ];
    "server" = [
      inputs.ucodenix.nixosModules.default
    ];
    "" = [
      inputs.ucodenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      inputs.stylix.nixosModules.stylix
      inputs.lanzaboote.nixosModules.lanzaboote
    ];
    "wsl" = [];
  };
  in 
  selected: pkgs.lib.lists.unique (builtins.concatLists (builtins.map (role: roles."${role}") ["common"] ++ selected));
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
  checks.${system} = {
    git-hooks = inputs.git-hooks.lib.${system}.run {
      src = nixpkgs.lib.cleanSource root;
      addGcRoot = true;
      hooks = {
        alejandra.enable = true;
        deadnix = {
          enable = true;
          excludes = ["^npins/"];
        };
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
        ../modules/common
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
        ../modules/common
        inputs.nix-topology.nixosModules.default
        inputs.nixos-wsl.nixosModules.default
      ];
    };

    # This is the main system configuration for the Talos server.
    talos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          inputs
          nixpkgs
          users
          root
          ;
        vars = vars.talos;
      };
      modules = [
        ./util/revision.nix
        ./hosts/talos
        ../modules/common
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
        inputs.home-manager.nixosModules.home-manager
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
        ../modules/common
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
          root
          ;
        vars = vars.godwaker;
      };
      modules = [
        ./util/revision.nix
        ./hosts/godwaker
        ../modules/common
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

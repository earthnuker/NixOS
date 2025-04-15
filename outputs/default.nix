{
  self,
  quadlet,
  deploy-rs,
  disko,
  lanzaboote,
  lix-module,
  # determinate,
  nix-index-database,
  nixos-facter-modules,
  nixos-hardware,
  nixpkgs,
  sops-nix,
  srvos,
  stylix,
  ...
} @ inputs: let
  system = "x86_64-linux";
  users = {
    earthnuker = import ./users/earthnuker;
  };
  sources = import ../npins;
  root = ./..;
  pkgs = nixpkgs.legacyPackages.${system};
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
    talos = {
      hostname = "talos.lan";
      sshUser = "root";
      fastConnection = true;
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.talos;
      };
    };
  };
  nixosConfigurations = {
    iso = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs nixpkgs;
      };
      modules = [
        ./installer
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
        drives = {
          system = "nvme-CT500P3PSSD8_25054DD6F3E8_1";
          storage = [
            "ata-ST12000VN0008-2YS101_WRS19TD0"
            "ata-ST12000VN0008-2YS101_WV70DWWZ"
            "ata-ST12000VN0008-2YS101_WRS1AY50"
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
        quadlet.nixosModules.quadlet
        sops-nix.nixosModules.sops
        (secrets [
          "duckdns_token"
          "tailscale_auth"
          "radarr_api_key"
          "sonarr_api_key"
          "vpn_env"
          "searxng_env"
          "talos_root_passwd"
          "homepage_env"
        ])
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
        stylix.nixosModules.stylix
        lanzaboote.nixosModules.lanzaboote
        lix-module.nixosModules.default
        # determinate.nixosModules.default
        nix-index-database.nixosModules.nix-index
        sops-nix.nixosModules.sops
      ];
    };
  };
}

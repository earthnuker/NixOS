{
  self,
  arion,
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
          system = "nvme-VMware_Virtual_NVMe_Disk_VMware_NVME_0000_1";
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
        arion.nixosModules.arion
        sops-nix.nixosModules.sops
        (secrets [
          "duckdns_token"
          "tailscale_auth"
          "radarr_api_key"
          "sonarr_api_key"
          "vpn_env"
          "searxng_env"
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

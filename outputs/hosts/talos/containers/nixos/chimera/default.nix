{
  lib,
  config,
  inputs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [13100 13101 13102];
  containers = {
    chimera = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.11";
      enableTun = true;
      bindMounts = {
        "/var/lib/ghidra" = {
          hostPath = "/mnt/data/ghidra";
          isReadOnly = false;
        };
        "/var/run/credentials/ts.auth" = {
          hostPath = config.sops.secrets.rescrap_tailscale_auth.path;
          isReadOnly = true;
        };
        "/var/run/dbus/system_bus_socket" = {
          hostPath = "/var/run/dbus/system_bus_socket";
          isReadOnly = true;
        };
      };
      nixpkgs = inputs.nixpkgs;
      config = {...}: {
        imports = [
          ./ghidra.nix
          ./tailscale.nix
          # ./dns-server.nix
          ./topology.nix
          inputs.nix-topology.nixosModules.default
        ];
        boot.isContainer = true;
        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [
              13100
              13101
              13102
            ];
          };
          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;
        };
        services.resolved.enable = true;
        system.autoUpgrade.enable = true;
        system.stateVersion = "24.05";
      };
    };
  };
}

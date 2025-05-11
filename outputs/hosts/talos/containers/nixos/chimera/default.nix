{
  lib,
  config,
  inputs,
  ...
}: {
  networking.nat = {
    enable = true;
    # Use "ve-*" when using nftables instead of iptables
    internalInterfaces = ["ve-+"];
    externalInterface = "enp3s0";
  };
  containers = {
    rescrap = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.11";
      additionalCapabilities = ["CAP_NET_ADMIN"];
      bindMounts = {
        "/var/lib/ghidra" = {
          hostPath = "/mnt/data/ghidra";
          isReadOnly = false;
        };
        "/var/run/credentials/ts.auth" = {
          hostPath = config.sops.secrets.rescrap_tailscale_auth.path;
          isReadOnly = true;
        };
      };
      config = {...}: {
        imports = [
          ./ghidra.nix
          ./tailscale.nix
          inputs.nix-topology.nixosModules.default
          ./topology.nix
        ];
        boot.isContainer = true;
        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [13100 13101 13102];
          };
          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;
        };
        services.resolved.enable = true;

        system.stateVersion = "24.05";
      };
    };
  };
}

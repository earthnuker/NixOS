{
  lib,
  inputs,
  ...
}: let
  std = inputs.nix-std.lib;
in {
  imports = [
    ./oci
    ./arion
    ./nixos
  ];
  virtualisation = {
    containers.enable = true;
    # quadlet.autoEscape = true;
    podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  environment.etc."containers/registries.conf.d/01-unqualified-docker.conf".text = std.serde.toTOML {
    unqualified-search-registries = [
      "quay.io"
      "ghcr.io"
      "gcr.io"
      "docker.io"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    13100
    13101
    13102 # Ghidra
  ];
}

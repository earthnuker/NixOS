{inputs, ...}: let
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
      "ghcr.io"
      "quay.io"
      "gcr.io"
      "docker.io"
    ];
  };
}

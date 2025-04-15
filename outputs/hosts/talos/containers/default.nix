inputs: {
  containers.test = {
    privateNetwork = true;
    config = import ./nixos/test.nix;
  };
  virtualisation = {
    containers.enable = true;
    oci-containers = {
      backend = "podman";
      containers = import ./oci;
    };
    # quadlet = import ./quadlet inputs;
    # arion = {
    #   backend = "podman-socket";
    #   projects.tvstack = {
    #     settings = import ./arion/tvstack.nix inputs;
    #   };
    # };
    docker = {
      enable = false;
      logDriver = "journald";
      daemon.settings = {
        data-root = "/mnt/data/docker";
        hosts = [
          "tcp://127.0.0.1:2375"
          "unix:///var/run/docker.sock"
        ];
      };
    };
    podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    13100
    13101
    13102 # Ghidra
  ];
}

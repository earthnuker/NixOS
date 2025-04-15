# Earthnuker's NixOS Machines

This repository contains the NixOS configurations for my machines. 

- [Godwaker](./outputs/hosts/godwaker/) (ThinkPad T470)
- [talos](./outputs/hosts/talos/) (NAS (B760M-ITX/D4 WiFi, i5-13400, 32GB, 500GB NVMe, 3x12TB HDD))

## Usage

The `sys` script acts as an entrypoint.

```shell
$ ./sys help
Available recipes:
    archive                                            # Archive flake inputs
    build_iso                                          # Build a bootable ISO
    check                                              # Flake check [alias: c]
    deploy *args                                       # Deploy configuration to defined hosts [alias: d]
    fix                                                # Archive flake inputs
    fmt
    gc                                                 # Clean nix-store and old generations (keep 10 or 1 week)
    gca                                                # Clean nix-store and all old generations
    getkey *HOSTS                                      # Retrieve age key for specified host and update .sops.yaml
    git                                                # Start lazygit
    help                                               # Show help
    history                                            # Show profile history [alias: h]
    provision flake host="nixos-installer.lan" $SSHPASS="toor" # Provision a host [alias: p]
    rekey                                              # Rekey secrets
    secrets                                            # Edit secrets
    shell                                              # Spawn shell with tools
    stage                                              # Stage all .nix files
    status                                             # Git status [alias: s]
    switch                                             # Build and switch [aliases: b, rebuild]
    update                                             # Update flake [alias: u]
```

## Provisioning a new machine

1. Clone the repository
2. Build installer iso and boot on new machine:
    ```shell
    $ sys build_iso
    ```
2. Provision the machine:
    ```shell
    $ sys provision <flake>
    ```

## Structure

- `outputs` contains flake outputs
    - `secrets` contains secrets
    - `users` contains user configurations (home-manager)
    - `util` contains utility modules
    - `hosts` contains host configurations
        - `talos` contains the configuration for Talos
            - `containers` contains the configuration for containers
                - `arion` contains docker-compose stacks for Arion
                - `nixos` contains NixOS systemd containers
                - `oci` contains OCI container configurations
                - `quadlet` contains quadlet pods
            - `disk-config` contains disk configurations
            - `hardware-configuration.nix` contains the configuration for hardware
            - `services` contains service configurations
                - `caddy.nix` contains the configuration for Caddy
                - `duckdns.nix` contains the configuration for DuckDNS
                - `homepage.nix` contains the configuration for Homepage-Dashboard
                - `monitoring.nix` contains Grafana+Prometheus setup
            - `networking.nix` contains the configuration network configuration
            - `quicksync.nix` contains the configuration for Intel QuickSync
        - `godwaker` contains the configuration for Godwaker
            - `disk-config` contains disk configurations
            - `boot.nix` contains the configuration for boot
            - `hardware-configuration.nix` contains the configuration for hardware
            - `networking.nix` contains the configuration network configuration
            - `services.nix` contains the configuration for services
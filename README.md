# Earthnuker's NixOS Machines

This repository contains the NixOS configurations for my machines.

- [godwaker](./outputs/hosts/godwaker/) (ThinkPad T470)
- [talos](./outputs/hosts/talos/) (NAS (B760M-ITX/D4 WiFi, i5-13400, 32GB, 500GB NVMe, 3x12TB HDD))
- [daedalus](./outputs/hosts/daedalus/) (ODROID C2)
- [helios](./outputs/hosts/helios/) (WSL on Work Laptop)
- tobit (old ASUS Laptop)

## Usage

The `sys` script acts as an entry-point.

```shell
$ ./sys help
Available recipes:
    archive                                    # Archive flake inputs
    build_iso                                  # Build a bootable ISO
    check                                      # Flake check [alias: c]
    cryptenroll device="/dev/nvme0n1p2"        # Set up automatic LUKS unlock
    deploy *args                               # Deploy configuration to defined hosts [alias: d]
    diagram                                    # Generate network diagram
    fix                                        # Archive flake inputs
    fmt                                        # Format nix files
    gc                                         # Clean nix-store and old generations (keep 10 or 1 week)
    gca                                        # Clean nix-store and all old generations
    getkey *HOSTS                              # Retrieve age key for specified host and update .sops.yaml
    git                                        # Start lazygit
    help                                       # Show help
    history                                    # Show profile history [alias: h]
    provision flake host="nixos-installer.lan" # Provision a host [alias: p]
    rekey                                      # Rekey secrets
    secrets                                    # Edit secrets
    shell                                      # Spawn shell with tools
    stage                                      # Stage all .nix files
    status                                     # Git status [alias: s]
    switch *args                               # Build and switch [aliases: b, rebuild]
    unsafe_deploy host                         # Deploy without automatic rollback
    update                                     # Update flake [alias: u]
```

## Provisioning a new machine

1. Clone the repository
2. Build installer iso and boot on new machine:

    ```shell
    $ sys build_iso
    [OUTPUT TRIMMED]
    ```

3. Provision the machine:

    ```shell
    $ sys provision <flake>
    [OUTPUT TRIMMED]
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
        - `nixos` contains NixOS containers
        - `oci` contains OCI container configurations
        - `quadlet` contains quadlet pods
      - `disk-config` contains disk configurations
      - `hardware-configuration.nix` contains the configuration for hardware
      - `services` contains service configurations
      - `networking.nix` contains the configuration network configuration
      - `quicksync.nix` contains the configuration for Intel QuickSync
    - `godwaker` contains the configuration for Godwaker
      - `disk-config` contains disk configurations
      - `boot.nix` contains the configuration for boot
      - `hardware-configuration.nix` contains the configuration for hardware
      - `networking.nix` contains the configuration network configuration
      - `services.nix` contains the configuration for services

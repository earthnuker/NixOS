# Earthnuker's NixOS Machines

This repository contains the NixOS configurations for my machines. 

- [Godwaker](./outputs/hosts/godwaker/) (ThinkPad T470)
- [spiritflame](./outputs/hosts/spiritflame/) (NAS (does not exist yet))

## Usage

The `sys` script acts as an entrypoint.

```shell
$ sys help #  Display help
Available recipes:
    archive                                            # Archive flake inputs
    check                                              # Flake check [alias: c]
    deploy *args                                       # Deploy configuration to defined hosts [alias: d]
    fix                                                # Archive flake inputs
    gc                                                 # Clean nix-store and old generations (keep 10 or 1 week)
    gca                                                # Clean nix-store and all old generations
    git                                                # Start lazygit
    help                                               # Show help
    history                                            # Show profile history [alias: h]
    provision flake host="nixos-installer.lan" $SSHPASS="toor" # Provision a host [alias: p]
    rekey                                              # Rekey secrets
    secret file                                        # Edit secrets
    shell                                              # Spawn shell with tools
    status                                             # Git status [alias: s]
    switch                                             # Build and switch [aliases: b, rebuild]
    update                                             # Update flake [alias: u]
```

## Structure

- `outputs` contains flake outputs
    - `secrets` contains secrets
    - `users` contains user configurations (home-manager)
    - `util` contains utility modules
    - `hosts` contains host configurations
        - `spiritflame` contains the configuration for Spiritflame
            - `containers` contains the configuration for containers
                - `arion` contains docker-compose stacks for Arion
                - `oci` contains OCI container configurations
            - `disk-config` contains disk configurations
            - `hardware-configuration.nix` contains the configuration for hardware
            - `services` contains service configurations
                - `caddy.nix` contains the configuration for Caddy
                - `duckdns.nix` contains the configuration for DuckDNS
                - `homepage.nix` contains the configuration for Homepage
            - `networking.nix` contains the configuration network configuration
            - `quicksync.nix` contains the configuration for Intel QuickSync
        - `godwaker` contains the configuration for Godwaker
            - `disk-config` contains disk configurations
            - `boot.nix` contains the configuration for boot
            - `hardware-configuration.nix` contains the configuration for hardware
            - `networking.nix` contains the configuration network configuration
            - `services.nix` contains the configuration for services
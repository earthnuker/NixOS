_default:
    @just --list

# Build and switch
switch: && archive
    nix flake update --commit-lock-file
    nh os switch -a -D nixdiff 

# Flake check
check:
    nix flake check --log-format multiline-with-logs

# show profile history
history:
    nix profile history --profile /nix/var/nix/profiles/system

# clean nix-store
gc:
    nh clean all -k 10 -K 1w
    nix store optimise
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive

archive:
    nix flake archive

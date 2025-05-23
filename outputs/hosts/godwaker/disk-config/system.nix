{drive}: {
  device = "/dev/disk/by-id/${drive}";
  type = "disk";
  content = {
    type = "gpt";
    partitions = {
      ESP = {
        type = "EF00";
        size = "512M";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = [
            "defaults"
            "umask=0077"
          ];
        };
      };
      root = {
        end = "-16G";
        content = {
          type = "luks";
          name = "cryptroot";
          settings = {
            allowDiscards = true;
            crypttabExtraOpts = ["tpm2-device=auto" "tpm2-measure-pcr=yes"];
          };
          postCreateHook = ''
            pcrs=7+11
            systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=$pcrs $device
          '';
          askPassword = true;
          content = {
            type = "btrfs";
            extraArgs = ["-f" "-L" "nixos"]; # Override existing partition
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = ["compress=zstd" "noatime"];
              };
            };
          };
        };
      };
      swap = {
        size = "100%";
        content = {
          type = "swap";
          randomEncryption = true;
          resumeDevice = true;
        };
      };
    };
  };
}

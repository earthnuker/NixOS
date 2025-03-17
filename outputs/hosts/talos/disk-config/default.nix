{
  drives,
  lib,
  pkgs,
  ...
}: {
  boot.swraid.mdadmConf = ''
    MAILADDR root
  '';

  systemd.services.mdadm-scrubbing = {
    # Scrub on next boot if system was powered off during last schedule.
    enable = true;
    description = "Mdadm Raid Array Scrubbing";
    startAt = "Sun 01:00:00";
    script = ''
      for md in /sys/block/md*; do
          echo check > "$md/md/sync_action"
      done
    '';
  };
  systemd.timers.mdadm-scrubbing.timerConfig.Persistent = true;

  disko.devices = {
    disk =
      (lib.genAttrs drives.storage (device: import ./mdadm_disk.nix {inherit device;}))
      // {
        system = import ./system.nix {drive = drives.system;};
      };

    mdadm = {
      pool = import ./pool.nix;
    };
  };
}

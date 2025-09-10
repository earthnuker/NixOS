{
  services = {
    zfs = {
      autoSnapshot.enable = false;
      autoScrub = {
        enable = true;
        interval = "*-*-1 23:00";
      };
      zed = {
        enableMail = true;
        settings = {
          ZED_DEBUG_LOG = "/tmp/zed.debug.log";

          ZED_EMAIL_ADDR = ["root"];
          ZED_EMAIL_PROG = "mail";
          ZED_EMAIL_OPTS = "-s '@SUBJECT@' @ADDRESS@";

          ZED_NOTIFY_INTERVAL_SECS = 3600;
          ZED_NOTIFY_VERBOSE = true;

          ZED_USE_ENCLOSURE_LEDS = true;
          ZED_SCRUB_AFTER_RESILVER = false;
        };
      };
    };
    sanoid = {
      enable = true;
      templates.backup = {
        hourly = 24;
        daily = 30;
        monthly = 12;
        autoprune = true;
        autosnap = true;
      };
      datasets."zpool/data" = {
        useTemplate = ["backup"];
      };
    };
    snapper = {
      snapshotRootOnBoot = true;
      persistentTimer = true;
      configs.root = {
        SUBVOLUME = "/";
        # create hourly snapshots
        TIMELINE_CREATE = true;
        # cleanup hourly snapshots after some time
        TIMELINE_CLEANUP = true;
        # limits for timeline cleanup
        TIMELINE_MIN_AGE = 1800;
        TIMELINE_LIMIT_HOURLY = 24;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 12;
        TIMELINE_LIMIT_YEARLY = 3;
      };
    };
  };
}

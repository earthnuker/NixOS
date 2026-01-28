{pkgs, ...}: {
  services.avahi = {
    enable = false;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };
  services.printing = {
    enable = false;
    startWhenNeeded = false;
    drivers = with pkgs; [canon-capt];
    defaultShared = true;
    browsing = true;
    listenAddresses = ["*:631"];
    allowFrom = ["all"];
    openFirewall = true;
    extraConf = ''
      DefaultEncryption Never
      ServerAlias *
    '';
  };
  systemd.services.ccpd = {
    enable = false;
    description = "Canon CAPT Printer Daemon";
    after = ["network.target" "cups.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "forking";
      ExecStart = "${pkgs.canon-capt}/sbin/ccpd";
      Restart = "always";
    };
  };
}

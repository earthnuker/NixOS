{pkgs, ...}: {
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };
  services.printing = {
    enable = true;
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
}

{pkgs, ...}: {
  services = {
    fstrim.enable = true;
    resolved.enable = true;
    ucodenix.enable = true;
    quassel = {
      enable = false;
      interfaces = ["0.0.0.0"];
    };
    k3s = {
      enable = false;
      role = "server";
    };
    kmscon = {
      enable = false;
      hwRender = false;
      useXkbConfig = true;
      fonts = [
        {
          name = "FiraCode";
          package = pkgs.nerd-fonts.fira-code;
        }
      ];
    };
    hardware = {
      bolt.enable = true;
    };
    tlp = {
      enable = false;
      settings = {
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      wireplumber.enable = true;
    };
    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      extraUpFlags = ["--ssh"];
    };
    fwupd.enable = true;
    openssh = {
      enable = true;
      settings.PermitRootLogin = "no";
    };
    upower.enable = true;
    picom.enable = false;
    devmon.enable = true;

    logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };
    dbus = {
      enable = true;
      packages = [pkgs.dconf];
    };
    seatd.enable = true;
  };
}

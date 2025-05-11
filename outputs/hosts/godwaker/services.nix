{
  pkgs,
  config,
  ...
}: let
  inherit (pkgs) lib;
in {
  services = {
    libinput.enable = false;
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
      enable = true;
      hwRender = true;
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
      enable = true;
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
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${lib.getExe pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
          user = "greeter";
        };
      };
    };
    fwupd.enable = true;
    openssh = {
      enable = true;
      settings.PermitRootLogin = "no";
    };
    upower.enable = true;
    picom.enable = true;
    devmon.enable = true;
    xrdp = {
      enable = true;
      defaultWindowManager = "i3";
      openFirewall = true;
    };
    logind = {
      lidSwitch = "ignore";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
    };
    autorandr = {
      enable = true;
    };
    dbus = {
      enable = true;
      packages = [pkgs.dconf];
    };
    seatd.enable = true;
    xserver = {
      enable = false;
      videoDrivers = ["modesetting"];
      xkb = {
        layout = "de";
        variant = "nodeadkeys";
      };
      synaptics = {
        enable = true;
        twoFingerScroll = true;
      };
      desktopManager = {
        xterm.enable = true;
      };
      windowManager = {
        awesome = {
          enable = false;
          noArgb = true;
          package = pkgs.awesome.override {
            lua = pkgs.luajit;
          };
          luaModules = [
            pkgs.luajitPackages.vicious
            pkgs.luajitPackages.luarocks
          ];
        };
        i3.enable = false;
        qtile.enable = false;
      };
      displayManager = {
        lightdm = {
          enable = false;
          greeters.mini = {
            enable = true;
            user = "earthnuker";
            extraConfig = ''
              [greeter]
              show-password-label = false
              [greeter-theme]
              background-image = ${config.stylix.image}
            '';
          };
        };
      };
    };
    displayManager = {
      defaultSession = "qtile";
    };
  };
}

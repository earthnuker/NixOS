{
  pkgs,
  config,
  ...
}: {
  services = {
    libinput.enable = false;
    fstrim.enable = true;
    resolved.enable = true;
    thelounge = {
      enable = true;
      plugins = with pkgs; [
        nodePackages.thelounge-theme-ion
        nodePackages.thelounge-theme-nord
        nodePackages.thelounge-theme-light
        nodePackages.thelounge-theme-chord
        nodePackages.thelounge-theme-abyss
        nodePackages.thelounge-theme-nologo
        nodePackages.thelounge-theme-crypto
        nodePackages.thelounge-theme-common
        nodePackages.thelounge-theme-amoled
        nodePackages.thelounge-theme-zenburn
        nodePackages.thelounge-theme-onedark
        nodePackages.thelounge-theme-gruvbox
        nodePackages.thelounge-theme-dracula
        nodePackages.thelounge-theme-classic
        nodePackages.thelounge-theme-midnight
        nodePackages.thelounge-theme-hexified
        nodePackages.thelounge-theme-bmorning
        nodePackages.thelounge-theme-bdefault
        nodePackages.thelounge-theme-solarized
        nodePackages.thelounge-theme-scoutlink
        nodePackages.thelounge-theme-mortified
        nodePackages.thelounge-theme-mininapse
        nodePackages.thelounge-theme-flat-dark
        nodePackages.thelounge-theme-flat-blue
        nodePackages.thelounge-theme-seraphimrp
        nodePackages.thelounge-theme-discordapp
        nodePackages.thelounge-theme-purplenight
        nodePackages.thelounge-theme-new-morning
        nodePackages.thelounge-theme-neuron-fork
        nodePackages.thelounge-theme-monokai-console
        nodePackages.thelounge-theme-dracula-official
        nodePackages.thelounge-theme-zenburn-monospace
        nodePackages.thelounge-theme-new-morning-compact
        nodePackages.thelounge-theme-amoled-sourcecodepro
        nodePackages.thelounge-theme-zenburn-sourcecodepro
        nodePackages.thelounge-theme-solarized-fork-monospace
      ];
      extraConfig = {
        defaults = {
          name = "BJZ";
          host = "irc.bonerjamz.us";
          port = 6697;
        };
      };
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
    };
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
          user = "greeter";
        };
      };
    };
    fwupd.enable = true;
    openssh.enable = true;
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

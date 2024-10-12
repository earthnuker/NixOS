# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  inputs,
  config,
  nixpkgs,
  lib,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
    #"${modulesPath}/installer/cd-dvd/iso-image.nix"
  ];
  # Bootloader.
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    kernelModules = ["rt2800usb"];
    plymouth = {
      enable = true;
    };
    #binfmt.emulatedSystems = ["aarch64-linux"];
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = lib.mkForce 0;
      systemd-boot = {
        enable = lib.mkForce false;
        configurationLimit = 120;
        consoleMode = "auto";
        editor = false;
        memtest86.enable = true;
        netbootxyz.enable = true;
      };
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    tmp = {
      useTmpfs = true;

      cleanOnBoot = true;
    };
    kernelParams = [
      # Silent Boot
      "quiet"
      "splash"
      "vga=current"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      # Audit
      # "audit=1"
    ];
    consoleLogLevel = 0;
    initrd = let
      uuid = {
        swap = "a95a5c26-c015-44eb-bc0c-6529e1e4bdfb";
      };
    in {
      systemd = {
        enable = true;
        tpm2.enable = true;
      };
      # https://github.com/NixOS/nixpkgs/pull/108294
      verbose = false;
      availableKernelModules = [
        "aesni_intel"
        "cryptd"
        "tpm_tis"
      ];
      luks.devices."luks-${uuid.swap}".device = "/dev/disk/by-uuid/${uuid.swap}";
    };
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;

      extraPackages = with pkgs; [
        intel-ocl
        intel-compute-runtime
        intel-media-driver
        vpl-gpu-rt
        vaapiVdpau
        libvdpau-va-gl
        (vaapiIntel.overrideAttrs (prev: {
          meta.priority = 1;
        }))
      ];
    };
  };

  networking = {
    hostName = "godwaker";
    firewall.enable = false;
    networkmanager = {
      enable = true;
      wifi = {
        macAddress = "stable";
        backend = "iwd";
      };
    };
  };

  time.timeZone = "Europe/Berlin";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "de_DE.UTF-8";
      LC_IDENTIFICATION = "de_DE.UTF-8";
      LC_MEASUREMENT = "de_DE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
      LC_NAME = "de_DE.UTF-8";
      LC_NUMERIC = "de_DE.UTF-8";
      LC_PAPER = "de_DE.UTF-8";
      LC_TELEPHONE = "de_DE.UTF-8";
      LC_TIME = "de_DE.UTF-8";
    };
  };

  # Configure console
  console = {
    earlySetup = true;
    font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
    packages = with pkgs; [terminus_font];
    useXkbConfig = true;
  };

  programs = {
    zsh.enable = true;
    ssh.startAgent = true;
    light.enable = true;
    dconf.enable = true;
    nix-ld.enable = true;
    nh = {
      enable = true;
      #clean.enable = true;
      clean.extraArgs = "-k 10 -K 1w";
      flake = "${config.users.users.earthnuker.home}/nixos";
    };
    mosh.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.commmon.default = "*";
  };

  users.users.earthnuker = {
    isNormalUser = true;
    description = "Earthnuker";
    extraGroups = ["networkmanager" "wheel" "docker" "dialout" "xrdp" "video"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCKtzQrqXob0eQDx9HHr0rEH3Ble4LnIuur670PYPt1EhAws597AD7RoUDGNTqGCWQw6amW0Bk8AJXKhxQmZw3H4MueRooQ+YBTMQBxeqCipOZCqh7ff98xo1l8fQUXOOQWq6hPw8CmRmf/TVzfybFAjGmNx2/AvoUgdzuQz5CL3Q=="
    ];
  };

  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm_bak";
    users = {
      earthnuker = import ./earthnuker.nix;
    };
  };
  nix = {
    channel.enable = false;
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = ["nixpkgs=${nixpkgs.outPath}"];
    optimise = {
      automatic = true;
      dates = ["09:00"];
    };
    settings = {
      warn-dirty = false;
      allow-dirty = false;
      trusted-users = ["@wheel"];
      max-jobs = "auto";
      experimental-features = ["nix-command" "flakes" "repl-flake"];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.lix.systems"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      ];
    };
  };
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      (nerdfonts.override {fonts = ["FiraCode"];})
    ];
  };

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  systemd.services = {
    NetworkManager-wait-online.enable = false;
    nix-daemon = {
      environment.TMPDIR = "/var/tmp";
    };
    "prepare-kexec".wantedBy = ["multi-user.target"];
  };

  environment = {
    systemPackages = with pkgs; [
      git
      htop
      neovim
      wget
      ripgrep
      direnv
      zoxide
      ncdu
      file
      linuxPackages.acpi_call
      sbctl
      iw
      dive
      docker-compose
      tpm2-tss
      # Nix
      # home-manager
      npins
      nix-output-monitor
      nix-prefetch
      nix-prefetch-git
      nix-prefetch-github
      nixd
      nix-zsh-completions
      nurl
      statix
      deadnix
      nix-web
      nix-tree
      greetd.tuigreet
    ];
    variables = {
      EDITOR = "nvim";
    };
    localBinInPath = true;
    pathsToLink = ["/share/xdg-desktop-portal" "/share/applications" "/libexec"];
  };

  services = {
    libinput.enable = false;
    fstrim.enable = true;
    kmscon = {
      enable = true;
      hwRender = true;
      useXkbConfig = true;
      fonts = [
        {
          name = "FiraCode";
          package = pkgs.nerdfonts;
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

  virtualisation.docker = {
    enable = true;
  };

  security = {
    tpm2 = {
      enable = true;
      tctiEnvironment.enable = true;
    };
    sudo.wheelNeedsPassword = true;
    rtkit.enable = true;
    polkit.enable = true;
    auditd.enable = false;
    audit = {
      enable = false;
      rules = [
        "-a exit,always -F arch=b64 -S execve"
        "-a exit,always -F arch=b32 -S execve"
      ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}

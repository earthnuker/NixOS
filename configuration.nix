# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  inputs,
  config,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  # Bootloader.
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    plymouth = {
      enable = true;
    };
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 120;
        consoleMode = "auto";
        editor = false;
        # memtest86.enable = true;
        # netbootxyz.enable = true;
      };
    };
    tmp.cleanOnBoot = true;
    # Silent Boot
    kernelParams = [
      "quiet"
      "splash"
      "vga=current"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
    consoleLogLevel = 0;
    initrd = {
      systemd.enable = true;
      # https://github.com/NixOS/nixpkgs/pull/108294
      verbose = false;
    };
  };

  boot.initrd.luks.devices."luks-a95a5c26-c015-44eb-bc0c-6529e1e4bdfb".device = "/dev/disk/by-uuid/a95a5c26-c015-44eb-bc0c-6529e1e4bdfb";
  networking.hostName = "godwaker"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  hardware = {
    bluetooth.enable = true;
    enableAllFirmware = true;
    opengl = {
      enable = true;
    };
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  # Configure console
  console = {
    earlySetup = true;
    font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
    packages = with pkgs; [terminus_font];
    useXkbConfig = true;
  };

  # Enable Z Shell
  programs = {
    zsh.enable = true;
    ssh.startAgent = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.earthnuker = {
    isNormalUser = true;
    description = "Earthnuker";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCKtzQrqXob0eQDx9HHr0rEH3Ble4LnIuur670PYPt1EhAws597AD7RoUDGNTqGCWQw6amW0Bk8AJXKhxQmZw3H4MueRooQ+YBTMQBxeqCipOZCqh7ff98xo1l8fQUXOOQWq6hPw8CmRmf/TVzfybFAjGmNx2/AvoUgdzuQz5CL3Q=="
    ];
  };

  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      earthnuker = import ./earthnuker.nix;
    };
  };

  # Enable flake support
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Trusted users
  nix.settings.trusted-users = ["@wheel"];

  # Perform garbage collection weekly to maintain low disk usage
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise = {
    automatic = true;
    dates = ["09:00"];
  };

  stylix = {
    enable = false;
    image = ./wallpaper.jpg;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    htop
    neovim
    wget
    ripgrep
    direnv
    # Nix
    home-manager
    npins 
    nix-output-monitor
    nix-prefetch
    nix-prefetch-git
    nix-prefetch-github
    nixd
    nvd
  ];

  environment.variables = {
    EDITOR = "nvim";
  };

  environment.pathsToLink = ["/share/xdg-desktop-portal" "/share/applications"];

  programs = {
    nix-ld.enable = true;
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 1w --keep 3";
      flake = "${config.users.users.earthnuker.home}/nixos";
    };
    mosh.enable = true;
  };

  # List services that you want to enable:

  services = {
    # kmscon = {
    #  enable = true;
    #  hwRender = true;
    #  extraConfig = ''
    #    xkb-layout=de
    #	xkb-variant=nodeadkeys
    #  '';
    #};
    tailscale.enable = true;
    fwupd.enable = true;
    openssh.enable = true;
    upower.enable = true;
    logind = {
      lidSwitch = "hybrid-sleep";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
    };
    autorandr = {
      enable = true;
    };
    xserver = {
      enable = true;
      xkb = {
        layout = "de";
        variant = "nodeadkeys";
      };
      desktopManager = {
        xterm.enable = true;
      };
      windowManager.awesome = {
        enable = true;
        noArgb = true;
        package = pkgs.awesome.override {
          lua = pkgs.luajit;
        };
        luaModules = [
          pkgs.luajitPackages.vicious
          pkgs.luajitPackages.luarocks
        ];
      };
      displayManager = {
        defaultSession = "none+awesome";
        lightdm = {
          enable = true;
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
  };

  # Virtualisation
  virtualisation.docker.enable = true;

  security.sudo.wheelNeedsPassword = false;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}

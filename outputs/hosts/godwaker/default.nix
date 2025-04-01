# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  inputs,
  config,
  nixpkgs,
  users,
  sources,
  root,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./boot.nix
    ./hardware.nix
    ./networking.nix
    ./environment.nix
    ./services.nix
    inputs.home-manager.nixosModules.home-manager
    #"${modulesPath}/installer/cd-dvd/iso-image.nix"
  ];

  nixpkgs.config.allowUnfree = true;

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
    nix-index-database.comma.enable = true;
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
    inherit users;
    extraSpecialArgs = {inherit inputs sources root;};
    useGlobalPkgs = false;
    useUserPackages = true;
    backupFileExtension = "hm_bak";
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
      warn-dirty = true;
      allow-dirty = true;
      trusted-users = ["@wheel" "earthnuker"];
      max-jobs = "auto";
      experimental-features = ["nix-command" "flakes"];
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

  stylix = {
    enable = false;
    image = ./wallpaper.jpg;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/spacemacs.yaml";
  };

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.fira-code
    ];
  };

  systemd.services = {
    NetworkManager-wait-online.enable = false;
    nix-daemon = {
      environment.TMPDIR = "/var/tmp";
    };
    "prepare-kexec".wantedBy = ["multi-user.target"];
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

{
  config,
  vars,
  pkgs,
  ...
}: {
  imports = [
    ./plasma.nix
    # ./gnome.nix
  ];
  stylix = {
    enable = true;
    image = vars.wallpaper;
    polarity = "dark";
    fonts.serif = config.stylix.fonts.sansSerif;
    enableReleaseChecks = false;
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/spacemacs.yaml";
  };
  environment.systemPackages = with pkgs;
    [
      kitty
    ]
    ++ (with pkgs.xorg; [
      libxcb
      xcbproto
      xcbutil
      xcbutilcursor
      xcbutilerrors
      xcbutilimage
      xcbutilkeysyms
      xcbutilrenderutil
      xcbutilwm
      wayland-utils
      xwayland
      kdePackages.xwaylandvideobridge
    ]);
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };
  programs.xwayland.enable = true;
  # boot.kernelParams = [
  #   "intel_idle.max_cstate=1"
  #   "i915.enable_dc=0"
  # ];
  qt = {
    enable = true;
  };
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
    config = {
      common.default = "*";
    };
  };
  services = {
    pulseaudio.enable = false;
    autorandr = {
      enable = true;
    };
    xrdp = {
      enable = true;
      openFirewall = true;
      # defaultWindowManager = "startplasma-x11";
    };
    libinput = {
      enable = true;
      touchpad.disableWhileTyping = true;
    };
    xserver = {
      enable = true;
      videoDrivers = [
        "intel"
        "modesetting"
      ];
      xkb = {
        layout = "de";
        variant = "nodeadkeys";
        options = "terminate:ctrl_alt_bksp";
      };
      # displayManager.sessionCommands = ''
      #   export QT_QPA_PLATFORM="wayland"
      # '';
      # synaptics = {
      #   enable = true;
      #   twoFingerScroll = true;
      # };
    };
  };
}

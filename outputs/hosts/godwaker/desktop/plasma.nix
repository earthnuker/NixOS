{
  pkgs,
  # lib,
  # config,
  # vars,
  ...
}: {
  nixpkgs.overlays = [
    # (_: prev: {
    #   baloo = prev.baloo.overrideAttrs (_: {
    #     postFixup =
    #       (prev.postFixup or "")
    #       + ''
    #         wrapProgram $out/libexec/kf6/baloo_file_extractor --set QT_QPA_PLATFORM offscreen
    #       '';
    #   });
    # })
  ];
  environment.systemPackages = with pkgs; [
    kde-rounded-corners
    kara
    # Qt6 stuff
    qt6.qtbase # Qt6 core, includes xcb plugin
    qt6.qtwayland # Qt6 Wayland plugin (so “wayland” backend exists)
  ];
  environment = {
    # sessionVariables = {
    #   QT_QPA_PLATFORM = "xcb";
    #   QT_QPA_PLATFORM_PLUGIN_PATH = "${pkgs.qt6.qtbase}/lib/qt-6/plugins/platforms";
    # };
    etc."xdg/baloofilerc".text = ''
      [Basic Settings]
      Indexing-Enabled=false
    '';
  };

  services.dbus.enable = true;
  programs.dconf.enable = true;

  services = {
    desktopManager.plasma6 = {
      enable = true;
      enableQt5Integration = true;
    };
    displayManager = {
      defaultSession = "plasma";
      sddm = {
        enable = true;
        wayland.enable = true;
        settings = {
          General = {
            DisplayServer = "wayland";
            GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
          };
          Theme = {
            EnableAvatars = "false";
          };
        };
      };
    };
  };
}

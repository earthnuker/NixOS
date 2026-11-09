{pkgs, ...}: {
  virtualisation.libvirtd = {
    enable = true;
    dbus.enable = true;
    qemu.swtpm.enable = true; # TPM 2.0 for Windows 11
  };

  services.cockpit = {
    enable = true;
    port = 9093;
    openFirewall = false;

    plugins = [
      pkgs.cockpit-machines
    ];

    allowed-origins = [
      "https://cockpit.talos.lan"
      "https://cockpit.talos.ts"
    ];

    settings.WebService = {
      AllowUnencrypted = true;
      ProtocolHeader = "X-Forwarded-Proto";
    };
  };
}

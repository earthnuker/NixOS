{
  imports = [
    ./chimera
    ./tvstack
  ];
  networking.nat = {
    enable = true;
    # Use "ve-*" when using nftables instead of iptables
    internalInterfaces = ["ve-+"];
    externalInterface = "enp3s0";
  };
}

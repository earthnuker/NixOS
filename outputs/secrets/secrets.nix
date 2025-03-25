let
  users = {
    earthnuker = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJG2CElVLBAG2MBde50PYg7y+BGV5y6fdvemFBuQiI1K";
  };

  systems = {
    godwaker = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBGzZ4k1mwRQ5pDqA686x5SG0Em5Dx0EU+gBvrqEq4hS";
    talos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFMMsYCv5VAZc0gu5XeQNLZEqYBKf20IUgPT62JQGRni";
  };
in {
  "tailscale.age".publicKeys = [
    users.earthnuker
    systems.talos
    systems.godwaker
  ];
  "rflood.env.age".publicKeys = [
    users.earthnuker
    systems.talos
  ];
  "qbt.env.age".publicKeys = [
    users.earthnuker
    systems.talos
  ];
  "duckdns.age".publicKeys = [
    users.earthnuker
    systems.talos
  ];
}

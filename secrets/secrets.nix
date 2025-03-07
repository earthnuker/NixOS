let
  earthnuker = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJG2CElVLBAG2MBde50PYg7y+BGV5y6fdvemFBuQiI1K";
  users = [earthnuker];

  godwaker = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBGzZ4k1mwRQ5pDqA686x5SG0Em5Dx0EU+gBvrqEq4hS";
  systems = [godwaker];
in {
  "test.age".publicKeys = users ++ systems;
}

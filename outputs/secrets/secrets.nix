let
  users = {
    earthnuker = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJG2CElVLBAG2MBde50PYg7y+BGV5y6fdvemFBuQiI1K";
  };

  systems = {
    godwaker = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBGzZ4k1mwRQ5pDqA686x5SG0Em5Dx0EU+gBvrqEq4hS";
    spiritflame = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3Hcw+AsMyTtIWhO58puB0z7v3TvyUV+FP1MhQV3CNn";
  };
in {
  "tailscale.age".publicKeys = [
    users.earthnuker
    systems.spiritflame
    systems.godwaker
  ];
  "rflood.env.age".publicKeys = [
    users.earthnuker
    systems.spiritflame
  ];
  "qbt.env.age".publicKeys = [
    users.earthnuker
    systems.spiritflame
  ];
  "duckdns.age".publicKeys = [
    users.earthnuker
    systems.spiritflame
  ];
  "sonarr_api_key.age".publicKeys = [
    users.earthnuker
    systems.spiritflame
  ];
  "radarr_api_key.age".publicKeys = [
    users.earthnuker
    systems.spiritflame
  ];
}

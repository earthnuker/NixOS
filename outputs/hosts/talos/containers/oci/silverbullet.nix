{
  image = "silverbulletmd/silverbullet:v2";
  hostname = "silverbullet";
  environment = {
    "SB_USER" = "admin:admin";
  };
  volumes = [
    "/mnt/data/silverbullet:/space"
  ];
}

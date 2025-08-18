{
  image = "silverbulletmd/silverbullet:v2";
  hostname = "silverbullet";
  ports = [
    "3888:3000"
  ];
  environment = {
    "SB_USER" = "admin:admin";
  };
  volumes = [
    "/mnt/data/silverbullet:/space"
  ];
}

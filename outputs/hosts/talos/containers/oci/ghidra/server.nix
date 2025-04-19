{config, ...}: rec {
  image = "blacktop/ghidra:alpine";
  hostname = "ghidra-server";
  cmd = ["server"];
  ports = [
    "13100:13100"
    "13101:13101"
    "13102:13102"
  ];
  volumes = [
    "/mnt/data/ghidra:/srv/repositories"
  ];
  extraOptions = [
    "--network=container:ghidra-tailscale"
  ];
  environment = {
    GHIDRA_USERS = "admin earthnuker strongleong";
    GHIDRA_PUBLIC_HOSTNAME = "ghidra";
  };
}

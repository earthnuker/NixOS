{
  image = "blacktop/ghidra";
  hostname = "ghidra";
  ports = [
    "13100:13100"
    "13101:13101"
    "13102:13102"
  ];
  volumes = [
    "/tank/ghidra:/repos"
  ];
  environment = {
    GHIDRA_USERS = "admin earthnuker strongleong";
    GHIDRA_PUBLIC_HOSTNAME = "ghidra.talos.lan";
  };
}

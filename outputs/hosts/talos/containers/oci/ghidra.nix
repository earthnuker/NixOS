{config, ...}: {
  image = "blacktop/ghidra:latest";
  hostname = "ghidra-ts";
  cmd = ["server"];
  volumes = [
    "/mnt/data/ghidra:/srv/repositories"
  ];
  extraOptions = [
    "--network=container:ghidra-ts"
  ];
  environment = {
    GHIDRA_USERS = "admin earthnuker strongleong";
    GHIDRA_PUBLIC_HOSTNAME = "ghidra";
  };
}

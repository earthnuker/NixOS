_: {
  services.k3s = {
    enable = true;
    role = "server";
    disable = ["traefik" "servicelb"];
    extraKubeProxyConfig = {
      nodePortAddresses = ["127.0.0.1/32"];
    };
  };
}

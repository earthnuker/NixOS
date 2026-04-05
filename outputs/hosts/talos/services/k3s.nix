{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
  ];

  environment.variables.KUBECONFIG = "/var/lib/rancher/k3s/agent/kubeproxy.kubeconfig";
  services.k3s = {
    enable = true;
    role = "server";
    disable = [
      "servicelb"
      "traefik"
    ];
  };
}

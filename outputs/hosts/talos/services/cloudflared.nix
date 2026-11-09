{config, ...}: {
  sops.secrets.cf_tunnel_creds = {};
  sops.secrets.cf_token = {};
  services.cloudflared = {
    enable = true;
    tunnels."149bba34-6ff4-4106-9be2-f1eb424901a2" = {
      default = "http_status:404";
      ingress = {
        "earthnuker.xyz" = "http://localhost:80";
      };
      credentialsFile = config.sops.secrets.cf_tunnel_creds.path;
    };
  };
  services.cloudflare-dyndns = {
    enable = true;
    apiTokenFile = config.sops.secrets.cf_token.path;
    domains = ["home.earthnuker.xyz"];
    ipv4 = true;
    ipv6 = false;
    proxied = false; # grey cloud: direct to your home IP
  };
}

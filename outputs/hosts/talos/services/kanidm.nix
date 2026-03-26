{
  config,
  pkgs,
  ...
}: let
  domain = "auth.talos.lan";
  certDir = "/var/lib/certs";
  genCertsScript = pkgs.writeShellScript "gen-kanidm-certs" ''
    mkdir -p ${certDir}
    ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 -keyout ${certDir}/key.pem -out ${certDir}/fullchain.pem -days 365 -nodes -subj "/CN=${domain}"
    chown -R caddy:sso ${certDir}
    chmod 644 ${certDir}/*.pem
  '';
  kani = pkgs.kanidmWithSecretProvisioning_1_8;
  port = 8443;
in {
  sops.secrets.kanidm = {
    owner = "kanidm";
    group = "kanidm";
  };
  users.groups.sso.members = ["caddy" "kanidm"];
  environment.systemPackages = [
    kani
  ];
  services.caddy.virtualHosts."${domain}:443".extraConfig = ''
    tls "${certDir}/fullchain.pem" "${certDir}/key.pem"
    reverse_proxy https://127.0.0.1:${toString port} {
       transport http {
        tls
        tls_insecure_skip_verify
        tls_server_name ${domain}
       }
    }
  '';
  system.activationScripts.genKanidmCerts = {
    text = "${genCertsScript}";
    deps = [];
  };
  services.kanidm = {
    package = kani;
    enableServer = true;
    serverSettings = {
      domain = "${domain}"; # Your domain
      origin = "https://${domain}";
      bindaddress = "[::]:${toString port}";
      ldapbindaddress = "[::]:3636";
      tls_key = "${certDir}/key.pem";
      tls_chain = "${certDir}/fullchain.pem";
    };
    enableClient = true;
    clientSettings = {
      uri = "https://127.0.0.1:${toString port}";
      verify_ca = false;
      verify_hostnames = false;
    };
    provision = {
      enable = true;
      autoRemove = true;
      acceptInvalidCerts = true;
      adminPasswordFile = config.sops.secrets.kanidm.path;
      idmAdminPasswordFile = config.sops.secrets.kanidm.path;
      groups = {
        admins = {};
        users = {};
        media = {};
      };
      persons = {
        earthnuker = {
          displayName = "Earthnuker";
          mailAddresses = ["earthnuker@gmail.com"];
          groups = ["admins" "users" "media"];
        };
      };
    };
  };
}

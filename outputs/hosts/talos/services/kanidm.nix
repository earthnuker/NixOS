{
  config,
  pkgs,
  ...
}: let
  domain = "idm.talos.lan";
  certDir = "/var/lib/certs";
  genCertsScript = pkgs.writeShellScript "gen-kanidm-certs" ''
    mkdir -p ${certDir}
    ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 -keyout ${certDir}/key.pem -out ${certDir}/fullchain.pem -days 365 -nodes -subj "/CN=${domain}"
    chown -R caddy:sso ${certDir}
    chmod 644 ${certDir}/*.pem
  '';
in {
  users.groups.sso.members = ["caddy" "kanidm"];
  environment.systemPackages = with pkgs; [
    kanidmWithSecretProvisioning_1_7
  ];
  services.caddy.virtualHosts."https://${domain}".extraConfig = ''
    tls "${certDir}/fullchain.pem" "${certDir}/key.pem"
    reverse_proxy https://127.0.0.1:8443 {
       transport http {
         tls_server_name ${domain}
       }
    }
  '';
  system.activationScripts.genKanidmCerts = {
    text = "${genCertsScript}";
    deps = [];
  };
  services.kanidm = {
    package = pkgs.kanidmWithSecretProvisioning_1_7;
    enableServer = true;
    serverSettings = {
      domain = "talos.lan"; # Your domain
      origin = "https://${domain}";
      bindaddress = "[::]:8443";
      ldapbindaddress = "[::]:3636";
      trust_x_forward_for = true;
      tls_key = "${certDir}/key.pem";
      tls_chain = "${certDir}/fullchain.pem";
    };

    enableClient = true;
    clientSettings.uri = config.services.kanidm.serverSettings.origin;
    provision = {
      enable = true;
      autoRemove = true;
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

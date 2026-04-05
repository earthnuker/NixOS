{config, ...}: let
  instance = "main";
  svc = config.services.authelia.instances."${instance}";
  authelia_secret = {
    inherit (svc) group;
    owner = svc.user;
  };
in {
  sops.secrets = {
    authelia_jwt = authelia_secret;
    authelia_session = authelia_secret;
    authelia_storage = authelia_secret;
    authelia_ldap_pass = authelia_secret;
  };
  services.authelia.instances.${instance} = {
    enable = true;
    secrets = with config.sops; {
      jwtSecretFile = secrets.authelia_jwt.path;
      sessionSecretFile = secrets.authelia_session.path;
      storageEncryptionKeyFile = secrets.authelia_storage.path;
    };
    environmentVariables = with config.sops; {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = secrets.authelia_ldap_pass.path;
    };
    settings = {
      theme = "auto";
      log = {
        level = "info";
        format = "text";
      };
      server = {
        address = "tcp://127.0.0.1:9091/";
        # url = "https://127.0.0.1:9091";
        endpoints.authz."forward-auth".implementation = "ForwardAuth";
      };
      authentication_backend = {
        password_reset.disable = true;
        ldap = rec {
          implementation = "lldap";
          address = "ldap://127.0.0.1:${toString config.services.lldap.settings.ldap_port}";
          base_dn = config.services.lldap.settings.ldap_base_dn;
          user = "uid=admin,ou=people,${base_dn}";
        };
      };
      storage.local.path = "/var/lib/authelia-${instance}/db.sqlite";
      notifier.filesystem.filename = "/var/lib/authelia-${instance}/notifications.txt";
      session = {
        name = "authelia";
        same_site = "lax";
        cookies = [
          {
            domain = "talos.lan";
            authelia_url = "https://auth.talos.lan";
          }
          {
            domain = "talos.ts";
            authelia_url = "https://auth.talos.ts";
          }
        ];
      };
      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "*.talos.lan";
            policy = "one_factor";
          }
          {
            domain = "*.talos.ts";
            policy = "one_factor";
          }
        ];
      };
    };
  };
}

{config, ...}: let
  lldap = config.services.lldap.settings;
in {
  sops.secrets.tinyauth_env = {};
  services.tinyauth = {
    enable = true;
    environmentFile = config.sops.secrets.tinyauth_env.path;
    settings = {
      AUTH_TRUSTEDPROXIES = "127.0.0.1";
      SERVER_ADDRESS = "127.0.0.1";
      SERVER_PORT = 3479;
      APPURL = "http://auth.talos.lan/";
      LDAP_ADDRESS = "ldap://localhost:${toString lldap.ldap_port}/";
      LDAP_BASEDN = lldap.ldap_base_dn;
      LDAP_BINDDN = "uid=${lldap.ldap_user_dn},ou=people,${lldap.ldap_base_dn}";
      LDAP_SEARCHFILTER = "(uid=%s)";
    };
  };
}

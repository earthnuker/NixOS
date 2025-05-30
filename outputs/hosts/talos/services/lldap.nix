{config, ...}: {
  services.lldap = {
    enable = true;
    settings = {
      http_host = "127.0.0.1";
      http_url = "http://dc.talos.lan";
      ldap_base_dn = "dc=talos,dc=lan";
      ldap_host = "127.0.0.1";
      ldap_user_email = "admin@admin";
      force_ldap_user_pass_reset = "always";
    };
    environmentFile = config.sops.secrets.lldap_env.path;
  };
}

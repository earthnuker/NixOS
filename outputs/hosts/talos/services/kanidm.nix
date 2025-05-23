{config, ...}: {
  services.kanidm = {
    enableServer = true;
    serverSettings = {
      tls_chain = config.sops.secrets."kanidm/tls_chain".path;
      tls_key = config.sops.secrets."kanidm/tls_key".path;
    };
  };
}

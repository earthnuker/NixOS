{config, ...}: {
  image = "povilasid/p110-exporter:latest";
  hostname = "p110-exporter";
  ports = [
    "127.0.0.1:9333:9333"
  ];
  environmentFiles = [
    config.sops.secrets.p110_exporter_env.path
  ];
}

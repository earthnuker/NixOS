{
  godwaker = {
    drives = {
      system = "nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX2J805949_1";
    };
    secrets = [
      "restic_password"
    ];
  };
  talos = {
    drives = {
      system = "nvme-CT500P3PSSD8_25054DD6F3E8_1";
      storage = [
        "ata-ST12000VN0008-2YS101_WRS19TD0"
        "ata-ST12000VN0008-2YS101_WV70DWWZ"
        "ata-ST12000VN0008-2YS101_WRS1AY50"
      ];
    };
    secrets = [
      "duckdns_token"
      "tailscale_auth"
      "radarr_api_key"
      "sonarr_api_key"
      "vpn_env"
      "searxng_env"
      "talos_root_passwd"
      "homepage_env"
      "authentik_env"
      "rescrap_tailscale_auth"
      "vodafone_station_passwd"
      "tapo_exporter_json"
      "lldap_env"
      "authelia_jwt"
      "authelia_storage"
    ];
  };
}

# ((file: builtins.fromJSON (builtins.readFile (pkgs.runCommand "" {} ''${lib.getExe pkgs.yj} > "$out" < "${file}"''))) ./secrets.yml).test

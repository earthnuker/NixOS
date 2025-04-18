{
  godwaker = {
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
      "ghidra_ts_env"
    ];
  };
}

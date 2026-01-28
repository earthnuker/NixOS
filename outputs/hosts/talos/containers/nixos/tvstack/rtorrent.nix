_: let
  hostname = "torrent.talos.lan";
in {
  services = {
    rtorrent = {
      enable = true;
      openFirewall = false;
      group = "nginx";
    };
    nginx.virtualHosts.${hostname}.listen = [
      {
        addr = "127.0.0.1";
        port = 5123;
      }
    ];
    rutorrent = {
      enable = true;
      nginx.enable = true;
      hostName = hostname;
      plugins = [
        "httprpc"
        "chunks"
        "data"
        "check_port"
        "diskspace"
        "edit"
        "erasedata"
        "theme"
        "throttle"
        "rss"
        "geoip"
        "trafic"
        "theme"
      ];
    };
  };
}

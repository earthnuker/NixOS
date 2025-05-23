/*
- name: Startpage
width: slim
hide-desktop-navigation: true
center-vertically: true
columns:
- size: full
    widgets:
      - type: search
        autofocus: true

      - type: monitor
        cache: 1m
        title: Services
        sites:
          - title: Jellyfin
            url: https://yourdomain.com/
            icon: si:jellyfin
          - title: Gitea
            url: https://yourdomain.com/
            icon: si:gitea
          - title: qBittorrent # only for Linux ISOs, of course
            url: https://yourdomain.com/
            icon: si:qbittorrent
          - title: Immich
            url: https://yourdomain.com/
            icon: si:immich
          - title: AdGuard Home
            url: https://yourdomain.com/
            icon: si:adguard
          - title: Vaultwarden
            url: https://yourdomain.com/
            icon: si:vaultwarden

      - type: bookmarks
        groups:
          - title: General
            links:
              - title: Gmail
                url: https://mail.google.com/mail/u/0/
              - title: Amazon
                url: https://www.amazon.com/
              - title: Github
                url: https://github.com/
          - title: Entertainment
            links:
              - title: YouTube
                url: https://www.youtube.com/
              - title: Prime Video
                url: https://www.primevideo.com/
              - title: Disney+
                url: https://www.disneyplus.com/
          - title: Social
            links:
              - title: Reddit
                url: https://www.reddit.com/
              - title: Twitter
                url: https://twitter.com/
              - title: Instagram
                url: https://www.instagram.com/
*/
_: {
  services.glance = {
    enable = true;
    settings = {
      server.port = 5678;
      theme = {
        "background-color" = "50 1 6";
        "primary-color" = "24 97 58";
        "negative-color" = "209 88 54";
      };
      pages = [
        {
          name = "Main";
          columns = [
            {
              size = "small";
              widgets = [
                {
                  type = "calendar";
                  first-day-of-week = "monday";
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "lobsters";
                  sort-by = "hot";
                  tags = [
                    "nix"
                    "rust"
                    "python"
                    "reversing"
                    "security"
                  ];
                }
              ];
            }
          ];
        }
      ];
    };
  };
}

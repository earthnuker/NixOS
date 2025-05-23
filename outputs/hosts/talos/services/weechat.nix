{pkgs, ...}: {
  services.weechat = {
    enable = true;
    headless = true;
    package = pkgs.weechat.override {
      configure = {availablePlugins, ...}: {
        plugins = builtins.attrValues (
          availablePlugins
          // {
            python = availablePlugins.python.withPackages (ps: with ps; [requests]);
          }
        );
        scripts = with pkgs.weechatScripts; [
          weechat-grep
          highmon
          colorize_nicks
          autosort
          weechat-go
          url_hint
        ];
      };
    };
  };
}

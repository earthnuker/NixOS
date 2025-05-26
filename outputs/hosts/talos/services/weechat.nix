{pkgs, ...}: let
  weechat = pkgs.weechat.override {
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
in {
  services.weechat = {
    enable = true;
    headless = true;
    package = weechat;
  };
}

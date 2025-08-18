{
  pkgs,
  config,
  ...
}: {
  users.users.coolbug = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.coolbug_passwd.path;
    shell = pkgs.zsh;
  };
  home-manager.users.coolbug = {
    imports = [./home.nix];
  };
}

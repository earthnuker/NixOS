{
  pkgs,
  config,
  inputs,
  ...
}: {
  programs.nh.flake = "${config.users.users.earthnuker.home}/nixos";
  users.users.earthnuker = {
    isNormalUser = true;
    description = "Earthnuker";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "dialout"
      "xrdp"
      "video"
      "audio"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys = {
      keyFiles = [inputs.ssh-keys-earthnuker.outPath];
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJeIHgefF8KgH0xl9LgDU5pZZ3tef/G/+jKQmKEmkzen zdfd\seiller.d@L-01201"
      ];
    };
  };
  home-manager.users.earthnuker = {
    imports = [./home.nix];
  };
}

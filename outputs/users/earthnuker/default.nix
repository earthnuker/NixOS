{
  pkgs,
  inputs,
  ...
}: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
    vendor = {
      completions.enable = true;
      config.enable = true;
      functions.enable = true;
    };
  };
  # environment.systemPackages = with pkgs; [
  #   iay
  # ];
  # programs.iay = {
  #   enable = true;
  #   minimalPrompt = false;
  # };
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
    shell = pkgs.fish;
    openssh.authorizedKeys = {
      keyFiles = [inputs.ssh-keys-earthnuker.outPath];
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJeIHgefF8KgH0xl9LgDU5pZZ3tef/G/+jKQmKEmkzen"
      ];
    };
  };
  home-manager.users.earthnuker = {
    imports = [./home.nix];
  };
}

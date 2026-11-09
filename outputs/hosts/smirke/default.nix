{pkgs, ...}: let
  starshipNu = pkgs.runCommand "starship-init.nu" {} ''
    ${pkgs.starship}/bin/starship init nu > "$out"
  '';

  nuConfig = pkgs.writeText "config.nu" ''
    $env.config.show_banner = false
    use ${starshipNu}
    def resys [] {
      rsync -Pav --info=progress2 earthnuker@godwaker:nixos ~
      ~/nixos/sys qswitch
    }
  '';
in {
  wsl = {
    defaultUser = "wsl";
    enable = true;
    ssh-agent.enable = true;
    interop.includePath = false;
  };
  users.users.wsl.extraGroups = ["whell" "docker"];
  virtualisation.docker.enable = true;
  networking = {
    hostName = "smirke";
    firewall.enable = false;
    networkmanager.enable = false;
  };
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      trusted-users = [
        "@wheel"
        "wsl"
      ];

      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://cache.lix.systems"
        "https://noctalia.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };
  nixpkgs.config.allowUnfreePredicate = _: true;
  environment.systemPackages = with pkgs; [
    ansible
    docker
    git
    helix
    jujutsu
    jjui
    jujutsu
    nushell
    openssh
    oyui
    starship
    opentofu
    opentofu-ls
    wget
    ansible-language-server
    nh
  ];
  programs = {
    nix-ld = {
      enable = true;
    };
    git = {
      enable = true;
      config.user = {
        name = "Daniel Seiller";
        email = "daniel.seiller@zdf.digital";
      };
    };
    bash.interactiveShellInit = ''
      if [[ $- == *i* && $EUID -ne 0 && -z "''${NIX_WSL_NO_NU:-}" ]]; then
        export NIX_WSL_NO_NU=1
        exec ${pkgs.nushell}/bin/nu --config ${nuConfig}
      fi
    '';
  };
  system.stateVersion = "24.05";
}

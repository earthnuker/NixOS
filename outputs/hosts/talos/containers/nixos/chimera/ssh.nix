{
  lib,
  pkgs,
  ...
}: let
  ghidraSelfService = pkgs.writeShellApplication {
    name = "ghidraSelfService";
    runtimeInputs = [pkgs.ghidra];
    text = ''
      echo "=== Ghidra Self-Service ==="
      echo "GitHub user : ''${GH_USER:-unknown}"
      # ghidra-svrAdmin -list
      # ghidra-svrAdmin -users
    '';
  };
in {
  environment.etc."scripts/ghAuth" = {
    text = ''
      #!${lib.getExe pkgs.bash}
      ${pkgs.curl}/bin/curl -sSfL https://github.com/earthnuker.keys | while read line; do
        echo 'environment="GH_USER=test"' $line
      done
    '';
    mode = "0555";
  };
  users.users.gh-key-verifier = {
    isSystemUser = true;
    group = "gh-key-verifier";
    home = "/var/lib/gh-key-verifier";
    createHome = true;
  };
  users.groups.gh-key-verifier = {};
  services.nscd = {
    enable = true;
  };
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    allowSFTP = false;
    passwordAuthentication = false;
    openFirewall = true;
    extraConfig = ''
      AllowTcpForwarding no
      X11Forwarding no
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AuthenticationMethods publickey
      Match User ghidra
        AuthorizedKeysCommand /etc/scripts/ghAuth %u %k
        AuthorizedKeysCommandUser root
        ForceCommand ${lib.getExe ghidraSelfService}
    '';
  };
}

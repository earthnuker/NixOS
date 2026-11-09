/*
https://git.lain.faith/haskal/dragnpkgs/src/branch/main/modules/ghidra-server/default.nix
https://github.com/kristoff3r/ghidra-plugins-nix/blob/1bfae431deb5097f4119e347288dde65f0e76631/nixos/default.nix
*/
{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (pkgs) ghidra;
  jdkPkg = pkgs.jdk25;
  directory = "ghidra";
  stateDir = "/var/lib/${directory}";
  ghidraHome = "${ghidra}/lib/ghidra";
  # LLDAP configuration
  ldapBaseDn = "dc=talos,dc=lan";
  lldapHost = "192.168.100.10";
  lldapPort = 3890;
  ghidraLdapGroup = "ghidra";

  classPath = with builtins; let
    input = lib.readFile "${ghidraHome}/Ghidra/Features/GhidraServer/data/classpath.frag";
    inputSplit = split "[^\n]*ghidra_home.([^\n]*)\n" input;
    paths = map head (filter isList inputSplit);
  in
    ghidraHome + (concatStringsSep (":" + ghidraHome) paths);
  mainClass = "ghidra.server.remote.GhidraServer";
  jaasConfig = pkgs.writeText "ghidra-jaas.conf" ''
    auth {
      com.sun.security.auth.module.LdapLoginModule REQUIRED
        userProvider="ldap://${lldapHost}:${toString lldapPort}/ou=people,${ldapBaseDn}"
        authIdentity="cn={USERNAME},ou=people,${ldapBaseDn}"
        userFilter="(&(uid={USERNAME})(memberOf=cn=${ghidraLdapGroup},ou=groups,${ldapBaseDn}))"
        useSSL=false
        debug=true;
    };
  '';

  args = "-a4 -u -autoProvision -p13100 -jaas ${jaasConfig} -ip ${config.networking.hostName} ${stateDir}";
in {
  users.users.ghidra = {
    isSystemUser = true;
    home = stateDir;
    group = "ghidra";
    shell = pkgs.bashInteractive;
  };
  users.groups.ghidra = {};
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "ghidra-svrAdmin" ''
      exec ${jdkPkg}/bin/java \
        -cp ${pkgs.ghidra}/lib/ghidra/Ghidra/Framework/Utility/lib/Utility.jar \
        -Djava.system.class.loader=ghidra.GhidraClassLoader \
        -Dfile.encoding=UTF8 \
        -Duser.country=US -Duser.language=en -Duser.variant= \
        -Xshare:off ghidra.Ghidra ghidra.server.ServerAdmin \
        ${pkgs.writeText "server.conf" "ghidra.repositories.dir=${stateDir}"} \
        "$@"
    '')
  ];
  systemd = {
    tmpfiles.rules = [
      "d ${stateDir}     0770 ghidra ghidra -"
    ];
    services.ghidra = {
      enable = true;
      description = "Ghidra server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${jdkPkg}/bin/java -classpath ${classPath} ${mainClass} ${args}";
        User = "ghidra";
        Group = "ghidra";
        SuccessExitStatus = 143;
        StateDirectory = directory;
        WorkingDirectory = stateDir;
        StateDirectoryMode = "0770";
        PrivateTmp = true;
        NoNewPrivileges = true;
        Environment = [
          "JAVA_HOME=${jdkPkg}"
          "GHIDRA_HOME=${ghidra}/lib/ghidra"
        ];
      };
    };
  };
}

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
  /*
  ghidra = pkgs.ghidra.overrideAttrs (old: {
    version = "11.4";
    versiondate = "20250620";
    mitmCache = pkgs.gradle.fetchDeps {
      inherit (old) pname;
      data = ./ghidra-deps.json;
    };
    src = pkgs.fetchFromGitHub {
      owner = "NationalSecurityAgency";
      repo = "Ghidra";
      tag = "Ghidra_11.4.1_build";
      hash = "sha256-zrNxbLgsnUnag82Mp0H6VGEVrhcqhkge7jrLxi8ZIIQ=";
      leaveDotGit = true;
      postFetch = ''
        cd "$out"
        git rev-parse HEAD > $out/COMMIT
        # 1970-Jan-01
        date -u -d "@$(git log -1 --pretty=%ct)" "+%Y-%b-%d" > $out/SOURCE_DATE_EPOCH
        # 19700101
        date -u -d "@$(git log -1 --pretty=%ct)" "+%Y%m%d" > $out/SOURCE_DATE_EPOCH_SHORT
        find "$out" -name .git -print0 | xargs -0 rm -rf
      '';
    };
    patches = pkgs.lib.filter (
      patch: !(pkgs.lib.hasInfix "0001-Use-protobuf-gradle-plugin" (builtins.baseNameOf patch))
    ) (old.patches or []);
  });
  */
  inherit (pkgs) ghidra;
  directory = "ghidra";
  stateDir = "/var/lib/${directory}";
  ghidraHome = "${ghidra}/lib/ghidra";
  classPath = with builtins; let
    input = lib.readFile "${ghidraHome}/Ghidra/Features/GhidraServer/data/classpath.frag";
    inputSplit = split "[^\n]*ghidra_home.([^\n]*)\n" input;
    paths = map head (filter isList inputSplit);
  in
    ghidraHome + (concatStringsSep (":" + ghidraHome) paths);
  mainClass = "ghidra.server.remote.GhidraServer";
  args = "-a0 -u -anonymous -p13100 -ip ${config.networking.hostName} ${stateDir}";
in {
  users.users.ghidra = {
    isSystemUser = true;
    home = stateDir;
    group = "ghidra";
  };
  users.groups.ghidra = {};
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
        ExecStart = "${pkgs.jdk}/bin/java -classpath ${classPath} ${mainClass} ${args}";
        User = "ghidra";
        Group = "ghidra";
        SuccessExitStatus = 143;
        StateDirectory = stateDir;
        WorkingDirectory = stateDir;
        StateDirectoryMode = "0770";
        PrivateTmp = true;
        NoNewPrivileges = true;
        Environment = [
          "JAVA_HOME=${pkgs.jdk}"
          "GHIDRA_HOME=${ghidra}/lib/ghidra"
        ];
      };
    };
  };
}

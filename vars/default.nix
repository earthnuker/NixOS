{
  pkgs,
  lib,
  ...
}: let
  # NOTE: This reads the *encrypted* file
  json = pkgs.runCommand "" {} ''${lib.getExe pkgs.yj} > "$out" < "${../secrets.yml}"'';
  data = lib.removeAttrs (builtins.fromJSON (builtins.readFile json)) ["sops"];
  mapped = lib.mapAttrsRecursive (path: _: lib.concatStringsSep "/" path) data;
  flattenAttrs = xs:
    builtins.concatLists (
      map (
        name: let
          v = xs.${name};
        in
          if builtins.isAttrs v
          then flattenAttrs v
          else [v]
      ) (builtins.attrNames xs)
    );
  secrets = flattenAttrs mapped;
in {
  daedalus = {};
  installer = {};
  godwaker = {
    inherit secrets;
    drives = {
      system = "nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX2J805949_1";
    };
    wallpaper = ./img/nitw.png;
    bootsplash = ./img/boot.webp;
  };
  talos = {
    inherit secrets;
    drives = {
      system = "nvme-CT500P3PSSD8_25054DD6F3E8_1";
      storage = [
        "ata-ST12000VN0008-2YS101_WRS19TD0"
        "ata-ST12000VN0008-2YS101_WV70DWWZ"
        "ata-ST12000VN0008-2YS101_WRS1AY50"
      ];
    };
  };
}

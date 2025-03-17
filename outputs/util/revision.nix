{
  self,
  nixpkgs,
  config,
  ...
} @ inputs: let
  self = inputs.inputs.self;
  revision =
    if self.sourceInfo ? dirtyShortRev
    then self.sourceInfo.dirtyShortRev
    else self.sourceInfo.shortRev or "dirty";
in {
  system.configurationRevision = revision;
  system.nixos.label =
    nixpkgs.lib.strings.concatStringsSep "-"
    ((nixpkgs.lib.sort (x: y: x < y) config.system.nixos.tags)
      ++ [
        "${config.system.nixos.version}:${(
          if self.sourceInfo ? dirtyShortRev
          then self.sourceInfo.dirtyShortRev
          else self.sourceInfo.shortRev
        )}"
      ]);
}

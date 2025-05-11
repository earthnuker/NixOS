{
  nixpkgs,
  config,
  ...
} @ inputs: let
  inherit (inputs.inputs) self;
  revision =
    self.sourceInfo.dirtyShortRev or (self.sourceInfo.shortRev or "dirty");
in {
  system.configurationRevision = revision;
  system.nixos.label =
    nixpkgs.lib.strings.concatStringsSep "-"
    ((nixpkgs.lib.sort (x: y: x < y) config.system.nixos.tags)
      ++ [
        "${config.system.nixos.version}:${(
          self.sourceInfo.dirtyShortRev or self.sourceInfo.shortRev
        )}"
      ]);
}

{pkgs, ...}:let
  tsFix = (old: {
    checkFlags =
      builtins.map (
        flag:
          if pkgs.lib.hasPrefix "-skip=" flag
          then flag + "|^TestGetList$|^TestIgnoreLocallyBoundPorts$|^TestPoller$"
          else flag
      )
      old.checkFlags;
  });
in {
  networking.domain = "lan";
  services.tailscale.package = pkgs.tailscale.overrideAttrs tsFix;
  nixpkgs.overlays = [
    (_: prev: {
      tailscale = prev.tailscale.overrideAttrs tsFix;
    })
  ];
}

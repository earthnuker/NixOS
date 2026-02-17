{inputs, ...}: {
  networking.domain = "lan";
  nixpkgs.overlays = [
    (final: _: {
      nh = inputs.nh.packages.${final.system}.default;
    })
  ];
}

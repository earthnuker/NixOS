{inputs, ...}: {
  networking.domain = "lan";
  nixpkgs.overlays = [
    (final: _: {
      nh = inputs.nh.packages.${final.system}.default;
      rom = inputs.rom.packages.${final.system}.default;
    })
  ];
}

{
  nixpkgs,
  rust-overlay,
  crane,
  system,
}: let
  overlays = [(import rust-overlay)];
  pkgs = import nixpkgs {
    inherit system overlays;
    config = {
      allowUnfree = true;
      packageOverrides = pkgs: {
        ffmpeg-full = pkgs.ffmpeg-full.override {
          withUnfree = true;
          withSamba = false;
          withSdl2 = false;
          withFrei0r = false;
          withTensorflow = false;
          withNvcodec = false;
          withAvisynth = false;
        };
      };
    };
  };
  python = pkgs.python3;
  py_env = python.withPackages (
    ps:
      with ps; [
        yt-dlp-light
        mastodon-py
      ]
  );
  rust-toolchain = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.minimal);
  craneLib = (crane.mkLib pkgs).overrideToolchain rust-toolchain;
  buildInputs = [];
  ffglitch = craneLib.buildPackage {
    inherit buildInputs;
    src = craneLib.cleanCargoSource ./ffglitch;
    strictDeps = true;
    doCheck = false;
    nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [pkgs.pkg-config];
  };
in {
  users.users.ffglitch = {
    isSystemUser = true;
    home = "/var/lib/ffglitch";
    createHome = true;
    extraGroups = [
      "video"
      "render"
    ];
  };
  system.tmpfiles.rules = [
    "d /var/lib/ffglitch ffglitch ffglitch -"
  ];
  systemd.services.ffglitch = {
    enable = true;
    description = "FFGlitch";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "ffglitch";
      Group = "ffglitch";
      WorkingDirectory = "/var/lib/ffglitch";
      Environment = [
        "PYTHON=${py_env.interpreter}"
        "MASTODON_CONFIG=${./mastodon.toml}"
        "CONFIG_FILE=${./config.toml}"
        "DL_PY=${./app/dl.py}"
        "RUST_LOG=info"
      ];
    };
    script = "${ffglitch}/bin/ffglitch";
    preStart = ''
      mkdir -p /var/lib/ffglitch
      chown -R ffglitch:ffglitch /var/lib/ffglitch
    '';
  };
}

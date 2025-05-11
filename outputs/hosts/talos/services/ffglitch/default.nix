{
  nixpkgs,
  rust-overlay,
  crane,
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
  py_env = python.withPackages (ps:
    with ps; [
      yt-dlp-light
      mastodon-py
    ]);
  rust-toolchain = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.minimal);
  craneLib =
    (crane.mkLib pkgs).overrideToolchain rust-toolchain;
  buildInputs = [];
  ffglitch = craneLib.buildPackage {
    inherit buildInputs;
    src = craneLib.cleanCargoSource ./ffglitch;
    strictDeps = true;
    doCheck = false;
    nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [pkgs.pkg-config];
  };
in {
  packages = {
    default = self.packages.${system}.docker;
    docker = let
      config_toml = pkgs.writeTextDir "config.toml" (builtins.readFile ./config.toml);
      mastodon_toml = pkgs.writeTextDir "mastodon.toml" (builtins.readFile ./mastodon.toml);
      dl_py = pkgs.writeTextDir "dl.py" (builtins.readFile ./app/dl.py);
    in
      pkgs.dockerTools.buildImage {
        name = "ffglitch";
        created = "now";
        tag = "latest";
        copyToRoot = pkgs.buildEnv {
          name = "image-root";
          pathsToLink = ["/"];
          paths = with pkgs; [
            dockerTools.fakeNss
            dockerTools.caCertificates
            dockerTools.binSh
            dockerTools.usrBinEnv
            ffmpeg-full
          ];
        };
        config = {
          Cmd = ["${ffglitch}/bin/ffglitch"];
          Env = [
            "TZDIR=${pkgs.tzdata}/share/zoneinfo"
            "TZ=Europe/Berlin"
            "PYTHON=${py_env.interpreter}"
            "MASTODON_CONFIG=${mastodon_toml}/mastodon.toml"
            "CONFIG_FILE=${config_toml}/config.toml"
            "DL_PY=${dl_py}/dl.py"
            "RUST_LOG=info"
          ];
        };
      };
  };
}

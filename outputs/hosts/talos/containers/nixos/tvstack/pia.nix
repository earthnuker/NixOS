{
  lib,
  pkgs,
  config,
  config',
  ...
}: let
  cfg = config.pia;

  # Map (tier,transport) -> public bundle name
  bundleName =
    if cfg.tier == "strong" && cfg.transport == "tcp"
    then "openvpn-strong-tcp"
    else if cfg.tier == "strong"
    then "openvpn-strong"
    else if cfg.transport == "tcp"
    then "openvpn-tcp"
    else "openvpn";

  # Path to your auth file (username on line 1, password on line 2)
  authUserPass = config'.sops.secrets.pia_auth.path;

  src = pkgs.fetchzip {
    url = "https://www.privateinternetaccess.com/openvpn/${bundleName}.zip";
    stripRoot = false;
    # First build: leave this as lib.fakeSha256 and copy the “got:” hash
    sha256 = "sha256-/zaZvrRz2+vqBxV3E35qhinmp4rxdFUfpLOXH3merao=";
  };

  # Normalize region string into a case-insensitive filename regex:
  # "de frankfurt" -> ".*de[-_ ]frankfurt.*"
  regionRegex = let
    lowered = lib.toLower cfg.region;
    pat = lib.replaceStrings [" " "_" "-"] (lib.replicate 3 "[-_ ]") lowered;
  in ".*${pat}.*";

  cleaned = pkgs.runCommand "pia-ovpn-cleaned" {} ''
    mkdir -p $out
    cp -r ${src}/* $out/

    shopt -s nullglob
    for f in $out/*.ovpn; do
      # 1) Strip the CRL block that OpenSSL 3.3 rejects
      awk 'BEGIN{keep=1} /<crl-verify>/{keep=0} keep{print} /<\/crl-verify>/{keep=1}' \
        "$f" > "$f.tmp" && mv "$f.tmp" "$f"

      # 2) Drop deprecated compression directives
      sed -i -e '/^compress\b/d' -e '/^comp-lzo\b/d' "$f"

      # 3) Ensure modern cipher negotiation; keep CBC as fallback
      grep -q '^data-ciphers ' "$f" || {
        printf '%s\n' \
          'data-ciphers AES-256-GCM:AES-128-GCM:AES-128-CBC' \
          'data-ciphers-fallback AES-128-CBC' >> "$f"
      }

      # 4) Force auth-user-pass to your secret path
      if grep -q '^auth-user-pass' "$f"; then
        sed -i "s#^auth-user-pass.*#auth-user-pass ${authUserPass}#" "$f"
      else
        echo "auth-user-pass ${authUserPass}" >> "$f"
      fi
    done
  '';

  # Pick the first .ovpn matching region; fall back to the first file if none match.
  files = builtins.attrNames (builtins.readDir cleaned);
  ovpns = builtins.filter (f: lib.hasSuffix ".ovpn" f) files;
  candidates = builtins.filter (f: builtins.match regionRegex (lib.toLower f) != null) ovpns;
  chosen = builtins.head (candidates ++ ovpns);
  chosenPath = "${cleaned}/${chosen}";
  chosenCfg = builtins.readFile chosenPath;

  protoOk = lib.strings.hasInfix ("proto " + cfg.transport) chosenCfg;
  svcName =
    lib.replaceStrings
    [" " "-" "." "/"] ["_" "_" "_" "_"]
    (
      if cfg.systemdName == null
      then "pia_" + cfg.region
      else cfg.systemdName
    );
in {
  #### User-facing options
  options.pia = {
    region = lib.mkOption {
      type = lib.types.str;
      default = "de frankfurt";
      description = ''
        Human-friendly region string to match against PIA .ovpn filenames
        (case-insensitive; spaces/underscores/hyphens are treated equally).
        Examples: "de frankfurt", "nl amsterdam", "us new york".
      '';
    };

    transport = lib.mkOption {
      type = lib.types.enum ["udp" "tcp"];
      default = "udp";
      description = "OpenVPN transport to require in the selected profile.";
    };

    tier = lib.mkOption {
      type = lib.types.enum ["default" "strong"];
      default = "strong";
      description = "PIA bundle: default (AES-128-CBC+SHA1) or strong (AES-256-CBC+SHA256).";
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to autostart the OpenVPN service.";
    };

    updateResolvConf = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to let OpenVPN manage resolv.conf (often false on NixOS containers).";
    };

    systemdName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional explicit service name; defaults to pia_<region>.";
    };
  };

  #### Module implementation
  config = {
    assertions = [
      {
        assertion = protoOk;
        message =
          "Selected PIA profile “${chosen}” does not use proto ${cfg.transport}. "
          + "Try switching `pia.transport`/`pia.tier` or adjust `pia.region`.";
      }
    ];

    services.openvpn.servers.${svcName} = {
      inherit (cfg) autoStart updateResolvConf;
      config = chosenCfg;
    };
  };
}

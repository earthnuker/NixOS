# Ghidra+LLDAP

Ghidra supports LDAP through JAAS mode `-a4`, using the JDK’s built-in `LdapLoginModule`. For LLDAP, the simplest configuration is authentication-only mode: Ghidra constructs the user’s LDAP DN and binds directly using the submitted password. This avoids storing a service-account password in the Ghidra container. ([GitHub][1])

Replace `-a0 -u` with `-a4 -jaas <file>`. Add `-autoProvision` when every successfully authenticated LLDAP user should automatically become a Ghidra server user.

## NixOS module changes

Adapt these values to your environment:

```nix
{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (pkgs) ghidra;

  directory = "ghidra";
  stateDir = "/var/lib/${directory}";
  ghidraHome = "${ghidra}/lib/ghidra";

  # LLDAP configuration
  ldapBaseDn = "dc=example,dc=com";
  lldapHost = "lldap.internal";
  lldapPort = 6360;

  classPath = with builtins; let
    input =
      lib.readFile
      "${ghidraHome}/Ghidra/Features/GhidraServer/data/classpath.frag";
    inputSplit = split "[^\n]*ghidra_home.([^\n]*)\n" input;
    paths = map head (filter isList inputSplit);
  in
    ghidraHome + (concatStringsSep (":" + ghidraHome) paths);

  mainClass = "ghidra.server.remote.GhidraServer";

  jaasConfig = pkgs.writeText "ghidra-jaas.conf" ''
    auth {
      com.sun.security.auth.module.LdapLoginModule REQUIRED
        userProvider="ldaps://${lldapHost}:${toString lldapPort}"
        authIdentity="uid={USERNAME},ou=people,${ldapBaseDn}"
        useSSL=true
        debug=false;
    };
  '';

  /*
    Use this when LLDAP's certificate is signed by an internal CA.

    The file contains only a public CA certificate, so putting the generated
    trust store in the Nix store is appropriate.
  */
  lldapTrustStore = pkgs.runCommand "lldap-truststore.p12" {
    nativeBuildInputs = [pkgs.jdk];
  } ''
    keytool \
      -importcert \
      -noprompt \
      -alias lldap-ca \
      -file ${./lldap-ca.crt} \
      -keystore "$out" \
      -storetype PKCS12 \
      -storepass changeit
  '';

  serverArgs = [
    "-a4"
    "-jaas"
    "${jaasConfig}"

    # Remove this if Ghidra users must be explicitly approved with svrAdmin.
    "-autoProvision"

    # Keep only if anonymous read-only access is actually wanted.
    # "-anonymous"

    "-p13100"
    "-ip"
    config.networking.hostName
    stateDir
  ];

  ghidraServerLauncher = pkgs.writeShellScript "ghidra-server" ''
    exec ${pkgs.jdk}/bin/java \
      -Djavax.net.ssl.trustStore=${lldapTrustStore} \
      -Djavax.net.ssl.trustStorePassword=changeit \
      -classpath ${lib.escapeShellArg classPath} \
      ${lib.escapeShellArg mainClass} \
      ${lib.escapeShellArgs serverArgs}
  '';
in {
  users.users.ghidra = {
    isSystemUser = true;
    home = stateDir;
    group = "ghidra";
    shell = pkgs.bashInteractive;
  };

  users.groups.ghidra = {};

  environment.systemPackages = [
    pkgs.openldap

    (pkgs.writeShellScriptBin "ghidra-svrAdmin" ''
      exec ${pkgs.jdk}/bin/java \
        -cp ${pkgs.ghidra}/lib/ghidra/Ghidra/Framework/Utility/lib/Utility.jar \
        -Djava.system.class.loader=ghidra.GhidraClassLoader \
        -Dfile.encoding=UTF8 \
        -Duser.country=US \
        -Duser.language=en \
        -Duser.variant= \
        -Xshare:off \
        ghidra.Ghidra \
        ghidra.server.ServerAdmin \
        ${pkgs.writeText "server.conf" ''
          ghidra.repositories.dir=${stateDir}
        ''} \
        "$@"
    '')
  ];

  systemd = {
    tmpfiles.rules = [
      "d ${stateDir} 0770 ghidra ghidra -"
    ];

    services.ghidra = {
      enable = true;
      description = "Ghidra server";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        ExecStart = "${ghidraServerLauncher}";

        User = "ghidra";
        Group = "ghidra";
        SuccessExitStatus = 143;

        StateDirectory = directory;
        StateDirectoryMode = "0770";
        WorkingDirectory = stateDir;

        PrivateTmp = true;
        NoNewPrivileges = true;

        Environment = [
          "JAVA_HOME=${pkgs.jdk}"
          "GHIDRA_HOME=${ghidraHome}"
        ];
      };
    };
  };
}
```

The JAAS section must be named exactly `auth`. `authIdentity` contains `{USERNAME}`, which the Java module replaces with the username entered in Ghidra. In authentication-only mode, no directory search is performed; Java binds directly as that DN. ([Oracle Docs][2])

## Verify the LLDAP user DN

Do not assume that your LLDAP installation uses `uid=` or `cn=` as its DN attribute. LLDAP’s own repository currently contains examples of both forms. Use whichever DN your server actually returns. ([GitHub][3])

From the container:

```bash
ldapsearch \
  -x \
  -H ldaps://lldap.internal:6360 \
  -D 'uid=admin,ou=people,dc=example,dc=com' \
  -W \
  -b 'ou=people,dc=example,dc=com' \
  '(uid=alice)' \
  dn
```

Example result:

```text
dn: uid=alice,ou=people,dc=example,dc=com
```

Then use:

```text
authIdentity="uid={USERNAME},ou=people,dc=example,dc=com"
```

If it returns:

```text
dn: cn=alice,ou=people,dc=example,dc=com
```

use:

```text
authIdentity="cn={USERNAME},ou=people,dc=example,dc=com"
```

Test the direct user bind independently of Ghidra:

```bash
ldapwhoami \
  -x \
  -H ldaps://lldap.internal:6360 \
  -D 'uid=alice,ou=people,dc=example,dc=com' \
  -W
```

Until that succeeds from inside the Ghidra container, Ghidra authentication will not succeed.

## Container-to-host networking

When the NixOS container uses `privateNetwork = true`, `127.0.0.1` inside the container refers to the container, not the host. The container should contact the `hostAddress` assigned in the host’s `containers.ghidra` configuration. NixOS creates a `ve-<container>` interface for this private link. ([NixOS Wiki][4])

For example, on the host:

```nix
containers.ghidra = {
  privateNetwork = true;
  hostAddress = "10.233.20.1";
  localAddress = "10.233.20.2";

  config = {
    networking.hosts."10.233.20.1" = [
      "lldap.internal"
    ];
  };
};

networking.firewall.interfaces."ve-ghidra".allowedTCPPorts = [
  6360
];
```

Also ensure LLDAP listens on `10.233.20.1` or `0.0.0.0`, rather than only `127.0.0.1`.

Check the actual interface name with:

```bash
ip link show
```

Linux interface names can be truncated when the container name is long.

If the container does not use `privateNetwork`, it shares the host’s network namespace and can normally reach an LLDAP listener on `127.0.0.1`.

## TLS

Use LDAPS for this integration. LDAP simple-bind credentials are otherwise transmitted without transport encryption; both Ghidra’s JAAS example and the JDK documentation warn about this. The JDK module uses SSL by default, but explicitly setting `useSSL=true` makes the intended configuration clear. ([GitHub][5])

The hostname in:

```text
ldaps://lldap.internal:6360
```

should appear in the certificate’s subject alternative names. Merely mapping an arbitrary name to the host address is insufficient when the certificate was issued for another hostname.

For a publicly trusted certificate, the custom `lldapTrustStore` and both `-Djavax.net.ssl.trustStore...` options can usually be removed. For an internal CA, the explicit trust store shown above is more deterministic than depending on whether a particular JDK package consumes the NixOS system CA bundle.

## Ghidra provisioning and permissions

LDAP authentication does not replace Ghidra’s own user and repository authorization database.

With:

```text
-autoProvision
```

a successful LDAP login automatically creates the corresponding Ghidra server user. Removing a user from LLDAP does not automatically remove the already provisioned Ghidra user. ([GitHub][1])

For an explicit allowlist, remove `-autoProvision` and add users manually:

```bash
sudo -u ghidra ghidra-svrAdmin -add alice
sudo -u ghidra ghidra-svrAdmin -add bob
```

Grant repository access separately:

```bash
sudo -u ghidra ghidra-svrAdmin -grant alice +w repository-name
sudo -u ghidra ghidra-svrAdmin -grant bob +r repository-name
```

Ghidra documents `+r`, `+w`, and `+a` as read-only, write, and repository-administrator permissions respectively. ([GitHub][1])

Finally, restart and inspect authentication diagnostics:

```bash
sudo systemctl restart ghidra
sudo journalctl -u ghidra -f
```

Temporarily set `debug=true` in `jaasConfig` when diagnosing DN, TLS, or bind failures; turn it off after the integration works.

[1]: https://github.com/NationalSecurityAgency/ghidra/blob/master/Ghidra/RuntimeScripts/server/svrREADME.md "ghidra/Ghidra/RuntimeScripts/server/svrREADME.md at master · NationalSecurityAgency/ghidra · GitHub"
[2]: https://docs.oracle.com/en/java/javase/21/docs/api/jdk.security.auth/com/sun/security/auth/module/LdapLoginModule.html "LdapLoginModule (Java SE 21 & JDK 21)"
[3]: https://github.com/lldap/lldap/blob/main/README.md?utm_source=chatgpt.com "lldap/README.md at main · lldap/lldap · GitHub"
[4]: https://wiki.nixos.org/wiki/NixOS_Containers "NixOS Containers - Official NixOS Wiki"
[5]: https://github.com/NationalSecurityAgency/ghidra/blob/master/Ghidra/RuntimeScripts/server/jaas.conf "ghidra/Ghidra/RuntimeScripts/server/jaas.conf at master · NationalSecurityAgency/ghidra · GitHub"

# Notes

## TPM2

```shell
sbctl verify
sbctl enroll-keys -- --microsoft
bootctl status
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7+11 /dev/nvme0n1p2
```

## Weechat

```shell
systemctl stop weechat
systemctl cat weechat.service | rg ^ExecStart=
sudo -u weechat /nix/store/...-weechat-bin-env-x.y.z/bin/weechat --dir /var/lib/weechat
systemctl start weechat
```

```shell
/mouse enable
/set irc.look.server_buffer independent
/set script.scripts.download_enabled on
/script install autosort.py autojoin.py go.py listbuffer.py
/key bind meta-j /go
/secure set relay <RELAY_PASSWORD>
/secure set LJR <PASSWORD>

/set irc.server_default.nicks earthnuker,earthnuker_
/set irc.server_default.username Earthnuker
/set irc.server_default.realname Earthnuker
/set irc.server_default.autojoin_dynamic on

/set weechat.look.nick_prefix "<"
/set weechat.look.nick_suffix ">"
/set weechat.look.prefix_same_nick " "

/set relay.network.bind_address 127.0.0.1
/set relay.network.password ${sec.data.relay}
/relay add ipv4.api 9000
/relay add ipv4.weechat 9001

/server add LJR irc.bonerjamz.us/6697 -ssl -auto
/set irc.server.LJR.sasl_mechanism plain
/set irc.server.LJR.sasl_username earthnuker
/set irc.server.LJR.sasl_password ${sec.data.LJR}

/set logger.mask.irc %Y/$server/$channel.%m-%d.log

/connect LJR
/join #idletown
/autosort
/autojoin --run
/save
```

```shell
/mouse enable
/secure set relay <RELAY_PASSWORD>
/remote addreplace talos http://wc.talos.ts:80/ -password=${sec.data.relay}
```

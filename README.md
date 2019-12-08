# Authentication server supporting the TUNroam protocol

Status: WIP

## Install

Run the following commands to install FreeRADIUS
and modify it to support the protocol:

```shell
git clone https://github.com/tunroam/auth-server.git
cd auth-server
./install.sh
```

`if` you enable
[other](https://stackoverflow.com/questions/22421290/scapy-operation-not-permitted-when-sending-packets)
protocols than TCP and UDP in `validate_anonid.py`,
you need:

```shell
cd /etc/freeradius/*/
setcap cap_net_raw=eip $(readlink -f `which python3`) || ( # if setcap fails:
  sed -i 's/user\ =\ freerad/user\ =\ root/g'   radiusd.conf;
  sed -i 's/group\ =\ freerad/group\ =\ root/g' radiusd.conf;
)
```

## TODO

Just `grep -r TODO`

- IPv6 support
- proxying of Protected EAP for `validate_certificate`
- applying filter rules

### Proxying

Why v3 won't work:

- http://lists.freeradius.org/pipermail/freeradius-users/2015-July/078749.html
- http://freeradius.1045715.n5.nabble.com/how-to-manage-dynamic-list-of-realms-td5751430.html
- http://lists.cistron.nl/pipermail/freeradius-users/2015-May/077378.html

We need v4

- https://wiki.freeradius.org/upgrading/version4/proxy
- https://wiki.freeradius.org/upgrading/version4/proxy-extensions
- https://github.com/FreeRADIUS/freeradius-server/blob/master/doc/antora/modules/installation/pages/upgrade.adoc#proxying
- https://wiki.freeradius.org/modules/Rlm_python
- https://github.com/FreeRADIUS/freeradius-server/blob/master/share/dictionary/freeradius/dictionary.freeradius.internal

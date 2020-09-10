# v4

Just run
```shell
./build.sh
```

## Possible solution to proxying

If we are unable to implement it in freeradius,
we can always generate freeradius config on the fly,
start a new server and proxy it to that one....

But this seems too ugly.


## links
- https://github.com/FreeRADIUS/freeradius-server/blob/a0dca10fced16e19f172fa2f708aac4d994250bc/raddb/mods-available/echo
- https://github.com/FreeRADIUS/freeradius-server/blob/17c0f3b6c23c1c86c374364f43a78a47ddd5e2a9/doc/antora/modules/raddb/pages/mods-available/echo.adoc
- https://github.com/FreeRADIUS/freeradius-server/blob/0ef24526b8fcc50af3389c551958ac7d8b1fdb47/raddb/mods-available/exec
- https://github.com/FreeRADIUS/freeradius-server/issues/2328
- https://github.com/FreeRADIUS/freeradius-server/issues/2304
- useful: https://github.com/FreeRADIUS/freeradius-server/issues/325
- https://github.com/FreeRADIUS/freeradius-server/issues/259
- https://github.com/FreeRADIUS/freeradius-server/blob/dc886b3208a405f736441eead7e537fc505e6cc2/scripts/exec-program-wait
- https://networkradius.com/doc/3.0.10/unlang/home.html
- https://github.com/FreeRADIUS/freeradius-server/issues/325
- https://github.com/FreeRADIUS/freeradius-server/blob/master/doc/antora/modules/installation/pages/upgrade.adoc#proxying
- http://lists.freeradius.org/pipermail/freeradius-users/2015-July/078760.html
- http://lists.cistron.nl/pipermail/freeradius-users/2015-May/077390.html
- https://github.com/FreeRADIUS/freeradius-server/blob/master/src/modules/rlm_radius/rlm_radius_udp.c#L166


#!/bin/sh
freeradius -X &
sleep 2
# src: https://github.com/FreeRADIUS/freeradius-server/issues/2351
echo "User-Name=06443_00testb@tunroam.lent.ink,Chap-Password=password" \
  | radclient -x localhost auth testing123

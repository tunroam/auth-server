#!/bin/bash
set -ve

FREERADIUS_ROOTDIR=/opt/freeradius

if [ ! -f /etc/debian_version ]; then
  echo "ERROR script targets Debian/Ubuntu systems"
  exit 1
fi

if [ ! -f /var/log/apt/history.log ] || \
  [ "$(date -r /var/log/apt/history.log +%F)" != "$(date +%F)" ]; then
  apt update
  apt upgrade -y
  apt dist-upgrade -y
fi

apt install -y \
  python3
# we first install python, so its already installed when installing freeradius
# https://stackoverflow.com/questions/45371531/failed-to-link-to-module-rlm-python-rlm-python-so
apt install -y \
  git \
  curl

# TODO, look at the proxy file from proxying branch
#cp append2proxy.conf /opt/freeradius/etc/raddb/
cp validate_anonid.py /usr/local/bin/ || echo already done in Dockerfile

ln -s $FREERADIUS_ROOTDIR/sbin/radiusd /usr/local/bin/freeradius
ln -s $FREERADIUS_ROOTDIR/bin/radclient /usr/local/bin/radclient
ln -s $FREERADIUS_ROOTDIR/etc/raddb/radiusd.conf /opt/freeradius/etc/raddb/freeradius.conf
cp mods-enabled_exec.conf "$FREERADIUS_ROOTDIR/etc/raddb/mods-enabled/exec" || echo already don in Dockerfile

cd $FREERADIUS_ROOTDIR/etc/raddb

# in section authorize in sites-enabled/default
# place call under filter_username
sed -i 's/filter_username$/filter_username\nexec/g' \
  sites-enabled/default \
  sites-enabled/inner-tunnel
# The inner-tunnel needs the clear-text password

cd -

if [[ -f /.dockerenv ]]; then
  echo "INFO inside docker container"
else
  echo "Please continue installing the network part"
fi

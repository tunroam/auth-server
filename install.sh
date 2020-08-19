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

# when using rlm_python we first installed python, so its already installed when installing freeradius
# but this isn't needed anymore since we use rlm_exec now
# https://stackoverflow.com/questions/45371531/failed-to-link-to-module-rlm-python-rlm-python-so
apt install -y \
  python3 \
  git \
  curl \
  dnsutils

# TODO, look at the proxy file from proxying branch
#cp append2proxy.conf /opt/freeradius/etc/raddb/
cp validate_anonid.py /usr/local/bin/ || echo already done in Dockerfile

ln -s $FREERADIUS_ROOTDIR/sbin/radiusd /usr/local/bin/freeradius
ln -s $FREERADIUS_ROOTDIR/bin/radclient /usr/local/bin/radclient
ln -s $FREERADIUS_ROOTDIR/etc/raddb/radiusd.conf /opt/freeradius/etc/raddb/freeradius.conf
cp mods-enabled_exec.conf "$FREERADIUS_ROOTDIR/etc/raddb/mods-enabled/exec" || echo "already done in Dockerfile"
cat /auth.conf >> $FREERADIUS_ROOTDIR/etc/raddb/sites-enabled/default

cd $FREERADIUS_ROOTDIR/etc/raddb

# in section authorize in sites-enabled/default
# place call under filter_username
for f in default inner-tunnel; do
  fp=sites-enabled/$f
  grep -B 9999 filter_username $fp > /tmp/tophalf
  grep -A 9999 filter_username $fp|grep -v filter_username > /tmp/bottomhalf
  mv /tmp/tophalf $fp
  cat /snippet_$f.conf >> $fp
  cat /tmp/bottomhalf >> $fp
  echo "$fp updated to include snippet"
done

grep -B 9999 'authenticate mschap' sites-enabled/default|grep -v 'authenticate mschap' > /tmp/tophalf
grep -A 9999 'authenticate mschap' sites-enabled/default > /tmp/bottomhalf
mv /tmp/tophalf          sites-enabled/default
cat snippet_auth.conf >> sites-enabled/default
cat /tmp/bottomhalf   >> sites-enabled/default

cd -

if [[ -f /.dockerenv ]]; then
  echo "INFO inside docker container"
else
  echo "Please continue installing the network part"
fi

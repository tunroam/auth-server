#!/bin/bash
set -ve

FREERADIUS_ROOTDIR=/opt/freeradius
TUNROAM_CONFIG_DIR=/tunroam-freeradius-conf

if [ ! -f /etc/debian_version ]; then
  echo "ERROR script targets Debian/Ubuntu systems"
  exit 1
fi

if [ ! -d $FREERADIUS_ROOTDIR ]; then
  echo "ERROR Freeradius is not installed, did you run build.sh?"
  exit 1
fi

if [ ! -f /var/log/apt/history.log ] || \
  [ "$(date -r /var/log/apt/history.log +%F)" != "$(date +%F)" ]; then
  echo "Apt not updated today, getting latest packages"
  apt update
  apt upgrade -y
  apt dist-upgrade -y
fi

apt install -y \
  python3 \
  git \
  curl \
  dnsutils \
  vim

# Scripts that are called by rlm_exec
cp $TUNROAM_CONFIG_DIR/validate_anonid.py /usr/local/bin/
cp $TUNROAM_CONFIG_DIR/validate-anonid-by-rlm_exec.sh /usr/local/bin/

# replace rlm_exec config and delete the echo example that uses rlm_exec
cp $TUNROAM_CONFIG_DIR/mods-enabled_exec.conf $FREERADIUS_ROOTDIR/etc/raddb/mods-available/exec
ln -fs $FREERADIUS_ROOTDIR/etc/raddb/mods-available/exec $FREERADIUS_ROOTDIR/etc/raddb/mods-enabled/exec
rm -f $FREERADIUS_ROOTDIR/etc/raddb/mods-enabled/echo

# add radius config block and enable the module
cp $TUNROAM_CONFIG_DIR/proxy-radius.conf $FREERADIUS_ROOTDIR/etc/raddb/mods-available/
ln -s $FREERADIUS_ROOTDIR/etc/raddb/mods-available/proxy-radius.conf $FREERADIUS_ROOTDIR/etc/raddb/mods-enabled/proxy-radius.conf
ln -s $FREERADIUS_ROOTDIR/etc/raddb/mods-available/radius $FREERADIUS_ROOTDIR/etc/raddb/mods-enabled/radius


# The following code adds an authorize in the sites-enabled
for f in default inner-tunnel; do
  fp=$FREERADIUS_ROOTDIR/etc/raddb/sites-available/$f
  grep -B 9999 filter_username $fp > /tmp/tophalf
  grep -A 9999 filter_username $fp|grep -v filter_username > /tmp/bottomhalf
  mv /tmp/tophalf                            $fp
  cat $TUNROAM_CONFIG_DIR/snippet_$f.conf >> $fp
  cat /tmp/bottomhalf                     >> $fp
  echo "$fp updated to include snippet"
done

# This adds another Auth-Type
fp=$FREERADIUS_ROOTDIR/etc/raddb/sites-available/default
grep -B 9999 'authenticate\ mschap' $fp|grep -v 'authenticate\ mschap' > /tmp/tophalf
grep -A 9999 'authenticate\ mschap' $fp > /tmp/bottomhalf
mv /tmp/tophalf                              $fp
cat $TUNROAM_CONFIG_DIR/snippet_auth.conf >> $fp
cat /tmp/bottomhalf                       >> $fp


# Ease calling of freeradius and radclient
ln -s $FREERADIUS_ROOTDIR/sbin/radiusd /usr/local/bin/freeradius
ln -s $FREERADIUS_ROOTDIR/bin/radclient /usr/local/bin/radclient
ln -s $FREERADIUS_ROOTDIR/etc/raddb/radiusd.conf $FREERADIUS_ROOTDIR/etc/raddb/freeradius.conf


if [[ -f /.dockerenv ]]; then
  echo "INFO inside docker container"
else
  echo "Please continue installing the network part"
  echo "https://github.com/tunroam/networking"
fi

#!/bin/bash
set -ve

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
chmod +x /usr/local/bin/validate_anonid.py

ln -s /opt/freeradius/sbin/radiusd /usr/local/bin/freeradius
ln -s /opt/freeradius/bin/radclient /usr/local/bin/radclient
ln -s /opt/freeradius/etc/raddb/radiusd.conf /opt/freeradius/etc/raddb/freeradius.conf


cd /opt/freeradius/etc/raddb

cat << 'EOF' > 'mods-enabled/exec'
# https://github.com/FreeRADIUS/freeradius-server/blob/master/raddb/mods-available/exec
exec {
	wait = yes
	program = "/usr/local/bin/validate_anonid.py %{User-Name}"
#	input_pairs = request
	output_pairs = reply
	shell_escape = yes
	timeout = 10
}
EOF

# in section authorize in sites-enabled/default
# place call under filter_username
sed -i 's/filter_username$/filter_username\nexec/g' \
  sites-enabled/default \
  sites-enabled/inner-tunnel
# The inner-tunnel needs the clear-text password

cd -

cat << EOF > /testscript.sh
freeradius -X &
sleep 2
# src: https://github.com/FreeRADIUS/freeradius-server/issues/2351
echo "User-Name=06443_00testb@tunroam.lent.ink,Chap-Password=password" \
  | radclient -x localhost auth testing123
EOF
chmod +x /testscript.sh


if [[ -f /.dockerenv ]]; then
  echo "INFO inside docker container"
else
  echo "Please continue installing the network part"
fi

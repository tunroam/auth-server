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

apt show freeradius \
  | grep Version \
  | grep -q "\ 3." || (echo "ERROR please upgrade your OS"; exit 1)

apt install -y \
  python \
  python3
# we first install python, so its already installed when installing freeradius
# https://stackoverflow.com/questions/45371531/failed-to-link-to-module-rlm-python-rlm-python-so
apt install -y \
  freeradius \
  curl \
  freeradius-python2


cp python3wrapper.py /etc/freeradius/*/mods-config/python/
cp validate_anonid.py /usr/local/bin/


cd /etc/freeradius/*/
# Since python3 is still not release, we use python2 to call python3
curl --silent -Lo mods-available/python3 \
  https://raw.githubusercontent.com/FreeRADIUS/freeradius-server/v3.0.x/raddb/mods-available/python3
#ln -s $PWD/mods-available/python3 \
#      $PWD/mods-enabled/python3

cat << 'EOF' > mods-enabled/python
# see mods-available/python for info
python{
  python_path = ${modconfdir}/${.:name}
  module = python3wrapper
  mod_authorize = ${.module}
  func_authorize = authorize
}
EOF

# in section authorize in sites-enabled/default
# place python under filter_username
sed -i 's/filter_username$/filter_username\npython/g' sites-enabled/default
cd -

cat << EOF > /testscript.sh
freeradius -X &
sleep 2
# src: https://github.com/FreeRADIUS/freeradius-server/issues/2351
echo "User-Name=06443_00testa@tunroam.lent.ink,Chap-Password=password" \
  | radclient -x localhost auth testing123
EOF
chmod +x /testscript.sh


if [[ -f /.dockerenv ]]; then
  echo "INFO inside docker container"
else
  echo "Please continue installing the network part"
fi

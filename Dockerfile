# This Dockerfile can be used while debugging the auth. server
# docker build -t freerad .
# docker run -it --rm -v $PWD/python3wrapper.py:/etc/freeradius/3.0/mods-config/python/python3wrapper.py freerad
# /testscript.sh # <= inside container

FROM debian

# https://github.com/FreeRADIUS/freeradius-server/blob/master/doc/antora/modules/installation/pages/source.adoc
RUN apt update; \
  apt upgrade -y; \
  apt dist-upgrade -y; \
apt install -y \
  python3 \
  libtalloc-dev \
  git \
  build-essential \
  cmake \
  libssl-dev; \
git clone https://github.com/mheily/libkqueue.git; \
  cd libkqueue; \
  cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib .; \
  make; \
  make install; \
  cd ..; \
git clone https://github.com/FreeRADIUS/freeradius-server.git; \
  cd freeradius-server;
#  ./configure > /tmp/configure.out 2>&1; \
#  make; \
#  make install;

RUN apt install -y \
  libpam-radius-auth \
  libpam-modules \
  python-dev \
  python3-dev \
  libosmocore

# dependencies TUNroam
RUN apt install -y \
  python \
  nftables \
  curl \
  bridge-utils \
  vim;

# dependencies from https://packages.debian.org/buster/freeradius
RUN apt install -y \
  libc6 \
  libcap2 \
  libct4 \
  libgdbm6 \
  libpam0g \
  libpcre3 \
  libperl5.28 \
  libreadline7 \
  libsqlite3-0 \
  libssl1.1 \
  libtalloc2 \
  libwbclient0 \
  lsb-base

# dependencies https://packages.debian.org/buster/freeradius-config
RUN apt install -y \
  adduser ca-certificates make openssl ssl-cert

# dependencies https://packages.debian.org/buster/libfreeradius3
RUN apt install -y \
  libc6 libcap2 libpcap0.8 libpcre3 libreadline7 libssl1.1 libtalloc2

WORKDIR /freeradius-server
RUN ./configure > /tmp/configure.out 2>&1; \
  make; \
  make install;

#CC src/lib/eap_aka_sim/state_machine.c
#src/lib/eap_aka_sim/state_machine.c: In function 'session_load_resume':
#src/lib/eap_aka_sim/state_machine.c:2079:3: warning: this statement may fall through [-Wimplicit-fallthrough=]
#   switch (eap_aka_sim_session->last_id_req) {
#   ^~~~~~
#src/lib/eap_aka_sim/state_machine.c:2105:2: note: here
#  case RLM_MODULE_REJECT:
#  ^~~~

# The following is WRONG! but I'm still debugging
RUN true || sed -i 's/,encrypt=.//' \
    /usr/local/share/freeradius/dictionary/radius/dictionary.*; \
  sed -i 's/encrypt=.//' \
    /usr/local/share/freeradius/dictionary/radius/dictionary.*; \
  sed -i 's/\ long$//' \
    /usr/local/share/freeradius/dictionary/radius/dictionary.*; \
  rm /usr/local/etc/raddb/mods-enabled/eap_inner; \
  mkdir -p /usr/local/etc/raddb/certs/rsa; \
  ln -s /freeradius-server/src/tests/certs/rsa/ca.pem \
    /usr/local/etc/raddb/certs/rsa/ca.pem;

#WORKDIR /src
#COPY * /src/
#RUN ./install.sh
#WORKDIR /etc/freeradius/3.0/
#ENV PREPROCESS_IGNORE_SOCKET_TESTS TRUE

# sed -i 's/buster\ main/buster\ main\ contrib\ non-free/' /etc/apt/sources.list

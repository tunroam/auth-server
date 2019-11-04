# This Dockerfile can be used while debugging the auth. server
# docker build -t freerad .
# docker run -it --rm -v $PWD/python3wrapper.py:/etc/freeradius/3.0/mods-config/python/python3wrapper.py freerad
# /testscript.sh # <= inside container

FROM debian

RUN apt update; \
  apt upgrade -y; \
  apt dist-upgrade -y; \
apt install -y \
  python \
  python3; \
apt install -y \
  freeradius \
  hostapd \
  nftables \
  curl \
  bridge-utils \
  freeradius-python2 vim

WORKDIR /src
COPY * /src/
RUN ./install.sh
WORKDIR /etc/freeradius/3.0/
#ENV PREPROCESS_IGNORE_SOCKET_TESTS TRUE


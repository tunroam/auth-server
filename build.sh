#!/bin/bash
set -ve

if [ ! which docker ]; then
  apt install docker.io
fi

curl -o /tmp/Dockerfile.deps \
  https://raw.githubusercontent.com/FreeRADIUS/freeradius-server/master/scripts/docker/build-ubuntu20/Dockerfile.deps
curl -o /tmp/Dockerfile.main \
  https://raw.githubusercontent.com/FreeRADIUS/freeradius-server/master/scripts/docker/build-ubuntu20/Dockerfile

docker build -t freeradius/ubuntu20-deps -f /tmp/Dockerfile.deps .
docker build -t freeradius/ubuntu20      -f /tmp/Dockerfile.main .
docker build -t tunroam/auth-server .

docker run -it --rm tunroam/auth-server

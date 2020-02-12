#!/bin/sh

cd /tmp/
git clone https://github.com/FreeRADIUS/freeradius-server.git
cd /tmp/freeradius-server/scripts/docker/build-debian10
docker build -t freeradius/debian10-deps -f Dockerfile.deps .
docker build -t freeradius/debian10 .


# https://raw.githubusercontent.com/FreeRADIUS/freeradius-server/master/scripts/docker/build-ubuntu20/Dockerfile.deps

ARG from=ubuntu:20.04
FROM ${from} AS base

ARG osname=focal

SHELL ["/usr/bin/nice", "-n", "5", "/usr/bin/ionice", "-c", "3", "/bin/sh", "-x", "-c"]

ONBUILD ARG osname=${osname}

ARG APT_OPTS="-y --option=Dpkg::options::=--force-unsafe-io --no-install-recommends"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
#  Development utilities
    apt-get install $APT_OPTS \
        devscripts \
        equivs \
        git \
        quilt \
        rsync \
        software-properties-common \
        wget && \
#  Compilers
    apt-get install $APT_OPTS \
        g++ && \
    bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)" && \
#  eapol_test dependencies
    apt-get install $APT_OPTS \
        libnl-3-dev \
        libnl-genl-3-dev && \
#  cmake to build libkqueue
    apt-get install $APT_OPTS \
        cmake

#
#  Documentation build dependecies
#

#  - doxygen & JSON.pm
RUN apt-get install $APT_OPTS \
        doxygen \
        graphviz \
        libjson-perl
#  - antora (npm needed)
RUN bash -c "$(wget -O - https://deb.nodesource.com/setup_10.x)" && \
    apt-get install $APT_OPTS \
        nodejs
RUN npm i -g @antora/cli@2.1 @antora/site-generator-default@2.1
#  - pandoc
RUN wget $(wget -qO - https://api.github.com/repos/jgm/pandoc/releases/latest | sed -ne 's/.*"browser_download_url".*"\(.*deb\)"/\1/ p') && \
    find . -mindepth 1 -maxdepth 1 -type f -name 'pandoc-*.deb' -print0 | \
        xargs -0 -r apt-get install $APT_OPTS && \
    find . -mindepth 1 -maxdepth 1 -type f -name 'pandoc-*.deb' -delete
#  - asciidoctor
RUN apt-get install $APT_OPTS \
        ruby-dev
RUN gem install asciidoctor


#
#  Setup a src dir in /usr/local
#
RUN mkdir -p /usr/local/src/repositories
WORKDIR /usr/local/src/repositories


#
#  Grab libkqueue and build
#
RUN git clone --branch master --depth=1 https://github.com/mheily/libkqueue.git

WORKDIR libkqueue
RUN cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib ./ && \
    make && \
    cpack -G DEB && \
    dpkg -i --force-all ./libkqueue*.deb


#
#  Shallow clone the FreeRADIUS source
#
WORKDIR /usr/local/src/repositories
ARG source=https://github.com/FreeRADIUS/freeradius-server.git
ARG branch=master
RUN git clone --depth 1 --no-single-branch -b ${branch} ${source}


#
#  Install build dependencies for all branches from v3 onwards
#
WORKDIR freeradius-server
RUN for i in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin 2>/dev/null | sed -e 's#origin/##' | egrep "^(v[3-9]*\.[0-9x]*\.x|master|${branch})$" | sort -u); \
    do \
        git checkout $i; \
        if [ -e ./debian/control.in ] ; then \
            debian/rules debian/control ; \
        fi ; \
        mk-build-deps -irt"apt-get -o Debug::pkgProblemResolver=yes $APT_OPTS" debian/control ; \
        apt-get -y remove libiodbc2-dev ; \
    done









# https://raw.githubusercontent.com/FreeRADIUS/freeradius-server/master/scripts/docker/build-ubuntu20/Dockerfile

FROM base as base2

SHELL ["/usr/bin/nice", "-n", "5", "/usr/bin/ionice", "-c", "3", "/bin/sh", "-x", "-c"]


ARG cc=gcc
ARG branch=master
ARG dh_key_size=2048

WORKDIR /usr/local/src/repositories/freeradius-server
RUN git checkout ${branch}
RUN CC=${cc} ./configure --prefix=/opt/freeradius
RUN make -j$(($(getconf _NPROCESSORS_ONLN) + 1))
RUN make install
WORKDIR /opt/freeradius/etc/raddb
RUN sed -i -e 's/allow_vulnerable_openssl.*/allow_vulnerable_openssl = yes/' radiusd.conf
RUN make -C certs DH_KEY_SIZE=$dh_key_size
WORKDIR /

FROM base
COPY --from=base2 /opt/freeradius /opt/freeradius

EXPOSE 1812/udp 1813/udp
ENV LD_LIBRARY_PATH=/opt/freeradius/lib
CMD ["/opt/freeradius/sbin/radiusd", "-X"]

RUN apt install -y vim python3 git curl dnsutils
RUN rm -f /opt/freeradius/etc/raddb/mods-enabled/echo
RUN ln -s /opt/freeradius/etc/raddb/mods-available/radius /opt/freeradius/etc/raddb/mods-enabled/radius
COPY snippet*.conf /
COPY install.sh /
RUN /install.sh
ENV TUNROAM_EXEC_DEBUG_PATH /var/log/validate_anonid.log
ENTRYPOINT ["/testscript.sh"]
WORKDIR /usr/local/src/repositories/freeradius-server
WORKDIR /opt/freeradius/etc/raddb

COPY /testscript.sh /
COPY validate_anonid.py /usr/local/bin/
COPY validate-anonid-by-rlm_exec.sh /usr/local/bin/
COPY mods-enabled_exec.conf /opt/freeradius/etc/raddb/mods-available/exec
COPY proxy-radius.conf /opt/freeradius/etc/raddb/mods-available/
RUN ln -fs /opt/freeradius/etc/raddb/mods-available/exec /opt/freeradius/etc/raddb/mods-enabled/exec
RUN ln -s /opt/freeradius/etc/raddb/mods-available/proxy-radius.conf /opt/freeradius/etc/raddb/mods-enabled/proxy-radius.conf


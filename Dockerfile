FROM freeradius/ubuntu20

RUN apt install -y vim python3 git curl dnsutils
COPY testscript.sh /
COPY tunroam-freeradius-conf /tunroam-freeradius-conf
COPY install.sh /
RUN /install.sh
ENV TUNROAM_EXEC_DEBUG_PATH /var/log/validate_anonid.log
ENTRYPOINT ["/testscript.sh"]

WORKDIR /usr/local/src/repositories/freeradius-server
WORKDIR /opt/freeradius/etc/raddb


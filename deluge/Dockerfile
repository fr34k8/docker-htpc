FROM ubuntu:16.04

RUN apt-get -q update \
    && apt-get install -qy software-properties-common \
    && add-apt-repository ppa:deluge-team/ppa \
    && apt-get update -q \
    && apt-get install -qy \
      deluged \
      deluge-web \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# install s6-overlay init manager (https://github.com/just-containers/s6-overlay)
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

# s6 service scripts
ADD 01-deluge-config  /etc/fix-attrs.d/01-deluge-config
ADD deluged-run.sh    /etc/services.d/deluged/run
ADD deluge-web-run.sh /etc/services.d/deluge-web/run

# Torrent port
EXPOSE 53160
EXPOSE 53160/udp
# WebUI
EXPOSE 8083
# Daemon
EXPOSE 9001

VOLUME /config
VOLUME /files

ENTRYPOINT ["/init"]

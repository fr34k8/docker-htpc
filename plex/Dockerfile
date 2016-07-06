FROM ubuntu:16.04

RUN apt-get update -q \
  && apt-get install -qy \
    wget \
  && apt-get -y autoremove \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

# download and install plex using the URL stored in the 'download_url' file
ADD download_url /download_url

RUN cd /tmp \
  && wget -q "`cat /download_url`" \
  && dpkg -i /tmp/*.deb \
  && rm -rf /tmp/*

# install s6-overlay init manager (https://github.com/just-containers/s6-overlay)
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

# s6 service scripts
ADD 01-plex-config   /etc/fix-attrs.d/01-plex-config
ADD plex-run.sh      /etc/services.d/plex/run

# plex config
ADD plexmediaserver /etc/default/plexmediaserver

EXPOSE 32400

VOLUME /config
VOLUME /files

WORKDIR /

ENTRYPOINT ["/init"]

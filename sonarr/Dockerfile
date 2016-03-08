FROM ubuntu:trusty

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC \
  && echo "deb http://apt.sonarr.tv/ master main" | tee -a /etc/apt/sources.list \
  && apt-get update -q \
  && apt-get install -qy \
    nzbdrone \
    mediainfo \
  && apt-get -y autoremove \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

# install s6-overlay init manager (https://github.com/just-containers/s6-overlay)
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

# s6 service scripts
ADD 01-sonarr-config   /etc/fix-attrs.d/01-sonarr-config
ADD sonarr-run.sh      /etc/services.d/sonarr/run

# http
EXPOSE 8989
# https
EXPOSE 9898

VOLUME /config
VOLUME /files

WORKDIR /opt/NzbDrone

ENTRYPOINT ["/init"]

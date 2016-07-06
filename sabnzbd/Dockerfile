FROM ubuntu:16.04

RUN apt-get -q update \
    && apt-get install -qy software-properties-common \
    && add-apt-repository -y  multiverse \
    && add-apt-repository -y  ppa:jcfp/ppa \
    && apt-get -q update \
    && apt-get install -qy \
      sabnzbdplus \
      par2 \
      python-yenc \
      unzip \
      unrar \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# install s6-overlay init manager (https://github.com/just-containers/s6-overlay)
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

# s6 service scripts
ADD 01-sabnzbd-config  /etc/fix-attrs.d/01-sabnzbd-config
ADD sabnzbd-run.sh     /etc/services.d/sabnzbd/run

EXPOSE 8080
EXPOSE 9090

VOLUME /config
VOLUME /files

ENTRYPOINT ["/init"]

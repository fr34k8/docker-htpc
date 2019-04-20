FROM ubuntu:18.04

RUN apt-get update -q \
  && apt-get install -qy software-properties-common \
  && add-apt-repository -y ppa:tikhonov/snapraid \
  && apt-get update -q \
  && apt-get install -qy \
    smartmontools \
    snapraid \
  && apt-get -y autoremove \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

ENTRYPOINT ["/usr/bin/snapraid"]

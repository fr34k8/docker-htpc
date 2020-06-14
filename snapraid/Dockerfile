FROM ubuntu:18.04

# TODO: upgrade to 20.04, but the PPA hasn't been updated to support focal yet

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

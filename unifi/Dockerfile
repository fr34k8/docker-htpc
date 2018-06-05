# https://hub.docker.com/r/linuxserver/unifi/
#FROM linuxserver/unifi:latest
FROM linuxserver/unifi:unstable

# remove x-frame-options header so that we can use this with muximux and organizr
RUN sed -i -e '/X-Frame-Options/d' \
  /usr/lib/unifi/webapps/ROOT/WEB-INF/resourcerewrite.xml \
  /usr/lib/unifi/webapps/ROOT/WEB-INF/urlrewrite.xml

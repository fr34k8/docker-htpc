FROM ghcr.io/linuxserver/unifi-controller:latest

# remove x-frame-options header so that we can use this with muximux and organizr
RUN sed -i -e '/X-Frame-Options/d' \
  /usr/lib/unifi/webapps/ROOT/WEB-INF/resourcerewrite.xml \
  /usr/lib/unifi/webapps/ROOT/WEB-INF/urlrewrite.xml

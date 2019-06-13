#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid nobody
/usr/bin/with-contenv deluge-web -c /config --do-not-daemonize -p 8083

#!/usr/bin/execlineb -P
s6-setuidgid nobody
/usr/bin/with-contenv deluge-web -c /config -p 8083

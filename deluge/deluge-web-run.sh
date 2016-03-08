#!/usr/bin/execlineb -P
s6-setuidgid nobody
deluge-web -c /config -p 8083

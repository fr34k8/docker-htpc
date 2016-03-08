#!/usr/bin/execlineb -P
s6-setuidgid nobody
deluged -d -c /config -p 9001 -L info

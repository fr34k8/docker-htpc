#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid nobody
/usr/bin/with-contenv deluged -d -c /config -p 9001 -L info

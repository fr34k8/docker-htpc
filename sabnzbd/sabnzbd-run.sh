#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid nobody
/usr/bin/sabnzbdplus --config-file /config/sabnzbd.ini --console --server 0.0.0.0:8085

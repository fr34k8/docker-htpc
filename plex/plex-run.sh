#!/usr/bin/execlineb -P
s6-setuidgid nobody
/usr/bin/with-contenv /usr/sbin/start_pms

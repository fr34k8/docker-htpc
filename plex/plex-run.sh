#!/usr/bin/execlineb -P
s6-setuidgid 65534:44
/usr/bin/with-contenv /usr/sbin/start_pms

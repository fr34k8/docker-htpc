#!/usr/bin/execlineb -P
#/usr/bin/with-contenv /usr/local/samba/sbin/nmbd -i --log-stdout
/usr/bin/with-contenv /usr/local/samba/sbin/nmbd -D -d 3 </dev/null
#/usr/bin/with-contenv /usr/local/samba/sbin/nmbd --foreground -i --log-stdout -d 3 </dev/null

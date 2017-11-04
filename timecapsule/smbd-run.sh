#!/usr/bin/execlineb -P
# add '-d <debuglevel>' (1, 2, 3 are good) for debug logging
#/usr/bin/with-contenv /usr/local/samba/sbin/smbd -i --log-stdout
#/usr/bin/with-contenv /usr/local/samba/sbin/smbd --log-stdout -d 3 </dev/null
/usr/bin/with-contenv /usr/local/samba/sbin/smbd -D </dev/null
#/usr/bin/with-contenv /usr/local/samba/sbin/smbd --foreground -i --log-stdout -d 3 </dev/null

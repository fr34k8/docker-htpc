#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid nobody
/usr/bin/with-contenv mono /opt/NzbDrone/NzbDrone.exe --no-browser -data=/config

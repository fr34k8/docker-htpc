#!/usr/bin/execlineb -P
s6-setuidgid nobody
mono /opt/NzbDrone/NzbDrone.exe --no-browser -data=/config

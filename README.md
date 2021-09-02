docker-htpc
===========

> :warning: This readme is NOT up to date. Just use the pieces as an example for your
> own configs.

Containers for HTPC apps.

All containers are built from the `ubuntu:trusty` base image because most of the
apps publish official .deb distributions for Ubuntu.

```
WARNING: This is a work in progress and suits my own specific needs. Feel free
to use pieces of it but I wouldn't recommend using it wholesale unless your
HTPC server setup is magically identical to mine.
```

init
----

All containers use [s6-overlay](https://github.com/just-containers/s6-overlay)
for process supervision and pre-startup scripts to fix permissions on the
/config volumes.

user
----

The apps inside the containers each run as the `nobody` user for security.
Permission dropping is handled by s6-overlay. Also, s6-overlay will run
`chown -R nobody /config` inside each container during startup to fix up the
perms in the /config volumes.

Volumes
-------

Each container generally follows a similar pattern for config and data volumes:

- `/files` -> `/files`: Large data volume. In my case, there are folders such
  as: `/files/tv_shows`, `/files/movies`, `/files/downloads`, etc.

- `/etc/<container_name>` -> `/config`: eg: `/etc/sabnzbd/` on the host is
   mapped to `/config` inside the sabnzbd
   container for persistent config storage.

This is not the case for all containers. Check the Makefile for details on
each container.

TODO: enumerate each container's host volume mounts here.

Ports
-----

- `organizr`:
  -  8282: http web ui
- `muximux`:
  - 8080: http web ui
- `tautulli`:
  - 8181: http web ui
- `sabzbd`:
  - 8085: http web ui
- `sonarr`:
  - 8989: http web ui
- `deluge`:
  - 8083: http web ui
  - *Note*: the deluge container is run with `--net=host` in order to allow deluge to punch holes with NAT-PMP. It will work
            fine without `--net=host` however, perhaps with limited connectivity to some torrent peers but more secure.
- `plex`:
  - network: `host`
- `embyserver`:
  - network: `host`
- `timecapsule`:
  - network: macvlan.
    - This container will be allocated its own IP on your local network based on the macvlan config.
    - Use `docker inspect` to view the allocated IP
    - See [timecapsule (Samba)](#timecapsule-samba) for more details.
- `unifi`:
  - network: macvlan.
    - This container will be allocated its own IP on your local network based on the macvlan config.
    - Use `docker inspect` to view the allocated IP
- `grafana`:
  - 3000: http web ui
- `graphite-api`:
  - network: `metrics`
  - No forwarded ports
- `go-carbon`:
  - 2003: graphite line protocol
- `influxdb`:
  - network: `metrics`
  - No forwarded ports
- `telegraf-snmp-unifi`:
  - network: `metrics`
  - No forwarded ports

Note: most of these apps can also expose TLS https ports but the current config
      does not expose these.

Usage
-----

### List tasks and descriptions

    $ make help

### Create and start containers

    $ make start

Containers will be created, started, and set with `--restart=always` flag.

### Update (rebuild + recreate) all containers

    $ make rebuild-all

### Update (rebuild + recreate) specific containers

    $ make rebuild CONTAINER=<name>

### Start/Stop/Restart individual containers

No make tasks for these since they're simple docker commands:

    $ docker ps
    $ docker stop sabnzbd
    $ docker start sabnzbd
    $ docker restart sabnzbd

### View container logs

Use `docker logs` command:

    $ docker logs sonarr
    $ docker logs -f sonarr

Notes
-----

### deluge autoconnect

Sonarr will not be able to connect to deluge unless you login to the deluge-web
client and select the server. This needs to be done once per startup of the
deluge container, unless auto-connect is enabled. Follow these directions
to setup deluge-web auto-connect: http://dev.deluge-torrent.org/wiki/Faq#HowdoIauto-connecttoaspecificdaemon

### timecapsule (Samba)

This container expects to connect to a docker network named `localnet`. This
network should be created with the macvlan or ipvlan drivers available in
docker 1.12+. This allows the container to be started and acquire its own
IP on your local network in order to run Bonjour (avahi) services to announce
itself on the network.

This is particular to my setup because I have an existing
samba instance running on the host providing general file sharing services. This
container acts as a separate device that looks roughly like a timecapsule on
the network exporting only a single `timemachine` mount.

It is probably possible to use standard Docker port mapping instead. See the
udp and tcp ports exposed in `timecapsule/Dockerfile`. However, getting the
avahi announcement to work could be challenging. A workaround would be to
publish the timecapsule services from the host's avahi using the
`timecapsule/smb.service` file.

If your local network is 192.168.0.0/24 you can create a `localnet` network
with the following docker command:

    $ docker network create -d macvlan \
        --subnet 192.168.0.0/24 \
        --gateway 192.168.0.1 \
        -o parent=eth0 \
        localnet

TimeMachine will attempt to use the entire disk by default. We constrain it
by lying about the max available space on the samba share. This is done using
a `dfree` script. By default, the max space presented to TimeMachine is 750GB.
This can be changed by updating the `TIMEMACHINE_MAX_VOL_SIZE_GB` environment
variable in the Dockerfile.

### metrics (grafana, graphite-api, go-carbon)

All three metrics containers are attached to a user-defined bridge network
named `metrics`. The only forwarded port is port 3000 (http) to the `grafana`
host.

Metrics are stored in `/etc/go-carbon/data` which is mounted into both the
`go-carbon` and `graphite-api` containers.

`grafana` fetches metrics from the `graphite-api` container over port 8000.

Metrics are sent to port 2003 which is forwarded into the `go-carbon` container,
example from host:

        echo "testdata.foo.bar $RANDOM $(date +%s)" | tee >&2 | nc localhost 2003

docker-htpc
===========

Containers for HTPC apps.

All containers are built from the `ubuntu:trusty` base image because they all
have official .deb distributions for ubuntu.

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

Each container follows a similar pattern for config and data volumes:

- `/files` -> `/files`:

Large data volume. In my case, there are folders such
as: `/files/tv_shows`, `/files/movies`, `/files/downloads`, etc.

- `/etc/<container_name>` -> `/config`:

eg: `/etc/sabnzbd/` on the host is mapped to `/config` inside the sabnzbd
container for persistent config storage.

Ports
-----

- `sabzbd`: http web ui on 8085
- `sonarr`: http web ui on 8989
- `deluge`: web UI on 8083. Note: the deluge container is run with `--net=host`
            in order to allow deluge to punch holes with NAT-PMP. It will work
            fine without `--net=host` however, perhaps with limited
            connectivity to some torrent peers.
- `plex`: 32400. Note this container is run with `--net=host`.
- `plexpy`: http web ui on 8181
- `couchpotato`: http web ui on 5050

Note: most of these apps can also expose TLS https ports but the current config
      does not expose these.

Usage
-----

### List tasks and descriptions

    $ make help

    build_all                      build all containers
    build_deluge                   build the deluge container
    build_sabnzbd                  build the sabnzbd container
    build_sonarr                   build the sonarr container
    create_all                     create and start all containers
    create_deluge                  create and start the deluge container
    create_sabnzbd                 create and start the sabnzbd container
    create_sonarr                  create and start the sonarr container
    help                           print list of tasks and descriptions
    remove_all                     remove all containers
    restart_all                    restart all containers
    stop_all                       stop all containers

### Build containers

    $ make build_all

### Create and start containers

    $ make create_all

Containers will be created, started, and set with `--restart=always` flag.

### Update all containers

    $ make stop_all
    $ make remove_all
    $ make build_all
    $ make create_all

This will rebuild each container, pulling down latest code for reach. Most
containers are built from .deb pkgs so this will depend on the upstream project
releasing a new .deb for the latest version.

### Update individual container

Stop the existing container, delete it, build a new one, create it:

    $ docker stop sabnzbd
    $ docker rm   sabnzbd
    $ make build_sabnzbd
    $ make create_sabnzbd

@TODO: make a single task for updating/re-creating an individual container..

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

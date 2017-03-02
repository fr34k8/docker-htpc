# adding a new container:
#  1. add <CONTAINER>_IMAGE var
#  2. add container name to CONTAINERS list
#  4. implement build_CONTAINER and create_CONTAINER tasks

# config
SABNZBD_IMAGE     = joemiller/sabnzbd
SONARR_IMAGE      = joemiller/sonarr
DELUGE_IMAGE      = joemiller/deluge
PLEX_IMAGE        = joemiller/plex
PLEXPY_IMAGE      = linuxserver/plexpy
COUCHPOTATO_IMAGE = linuxserver/couchpotato
TIMECAPSULE_IMAGE = joemiller/timecapsule
MUXIMUX_IMAGE     = linuxserver/muximux

CONTAINERS = sabnzbd sonarr deluge plex plexpy couchpotato timecapsule muximux

# A docker network will be created for containers (such as 'timecapsule') that require
# their own IP address on the local network (similar to a VM in bridge networking mode).
NETWORK_NAME=localnet-v6only
NETWORK_IFACE=br0
# NOTE: --subnet=2001::0/64 is a "dummy" network. This is required for docker 1.12.4+ which requires a
#       --subnet if --ipv6 is specified. Your network should use IPv6 SLAAC so that the container will
#       automatically acquire an ipv6 address from the real local subnet.
NETWORK_CREATE_CMD=docker network create -d macvlan --ipv6 --subnet=2001::0/64 -o parent=$(NETWORK_IFACE) $(NETWORK_NAME)

# helper tasks
_configure_network:
	@docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || $(NETWORK_CREATE_CMD)

_remove_network:
	docker network rm $(NETWORK_NAME)

# aggregate tasks
# build_all: build_sabnzbd build_sonarr build_deluge build_plex build_plexpy build_couchpotato ## build all containers

# create_all: _configure_network create_sabnzbd create_sonarr create_deluge create_plex create_plexpy create_couchpotato ## create and start all containers

# stop_all:  ## stop all containers
# 	docker stop $(CONTAINERS)

# restart_all:  ## restart all containers
# 	docker restart $(CONTAINERS)

# remove_all:  ## remove all containers
# 	docker rm $(CONTAINERS)

# sabnzbd
build_sabnzbd:  ## build the sabnzbd container
	docker build -t $(SABNZBD_IMAGE) --pull=true --no-cache=true sabnzbd

create_sabnzbd:  ## create and start the sabnzbd container
	docker run -d --name sabnzbd --restart=always \
		-p 8085:8085 \
		-v /files:/files \
		-v /etc/sabnzbd:/config \
		$(SABNZBD_IMAGE)

# sonarr
build_sonarr:  ## build the sonarr container
	docker build -t $(SONARR_IMAGE) --pull=true --no-cache=true sonarr

create_sonarr:  ## create and start the sonarr container
	docker run -d --name sonarr --restart=always \
		-e XDG_CONFIG_HOME=/config \
		-p 8989:8989 \
		-v /files:/files \
		-v /etc/sonarr:/config \
		$(SONARR_IMAGE)

upgrade_sonarr: ## upgrade and launch a new sonarr container
	$(MAKE) build_sonarr && \
	   	(docker inspect sonarr >/dev/null && { docker stop sonarr && docker rm sonarr; } || true) \
		&& $(MAKE) create_sonarr

# deluge
build_deluge:  ## build the deluge container
	docker build -t $(DELUGE_IMAGE) --pull=true --no-cache=true deluge

create_deluge:  ## create and start the deluge container
	docker run -d --name deluge --restart=always \
		-p 8083:8083 \
		-p 53160:53160 \
		--net=host \
		-v /files:/files \
		-v /etc/deluge:/config \
		$(DELUGE_IMAGE)

# plex
build_plex:  ## build the plex container
	./plex/plexupdate.sh -r | tail -1 | tee ./plex/download_url
	# echo 'https://downloads.plex.tv/plex-media-server/1.0.3.2461-35f0caa/plexmediaserver_1.0.3.2461-35f0caa_amd64.deb' | tee ./plex/download_url
	docker build -t $(PLEX_IMAGE) --pull=true --no-cache=true plex

create_plex:  ## create the plex container
	@echo "NOTE: make sure you have run 'chown -R nobody:nobody /etc/plex' before creating the plex container."
	docker run -d --name plex --restart=always \
		-p 32400:32400 \
		--net=host \
		-v /files:/files \
		-v /etc/plex:/config \
		$(PLEX_IMAGE)

upgrade_plex: ## upgrade and launch a new plex container
	$(MAKE) build_plex && \
	   	(docker inspect plex >/dev/null && { docker stop plex && docker rm plex; } || true) \
		&& $(MAKE) create_plex

# plexpy
build_plexpy: ## build the plexpy container
	docker pull $(PLEXPY_IMAGE)

create_plexpy:  ## create the plexpy container
	docker run -d --name plexpy --restart=always \
		-e PUID=65534 -e PGID=65534 \
		-p 8181:8181 \
		-v /etc/plexpy:/config \
		-v /etc/localtime:/etc/localtime:ro \
		$(PLEXPY_IMAGE)

upgrade_plexpy: ## upgrade and restart the plexpy container
	# we use the linuxserver/plexpy image which auto-upgrades on restart
	docker restart plexpy

# couchpotato
build_couchpotato: ## build the couchpotato container
	docker pull $(COUCHPOTATO_IMAGE)

create_couchpotato:  ## create the couchpotato container
	docker run -d --name couchpotato --restart=always \
		-e PUID=65534 -e PGID=65534 \
		-p 5050:5050 \
		-v /etc/localtime:/etc/localtime:ro \
		-v /etc/couchpotato:/config \
		-v /files/usenet/downloads:/downloads \
		-v /files/movies:/movies \
		$(COUCHPOTATO_IMAGE)

# timecapsule (samba)
build_timecapsule:  ## build the timecapsule (samba) container
	docker build -t $(TIMECAPSULE_IMAGE) --pull=true timecapsule

create_timecapsule: _configure_network ## create and start the timecapsule (samba) container
	docker run -d --name timecapsule --restart=always \
		--hostname=timecapsule \
		--net=$(NETWORK_NAME) \
		-v /files/timemachine:/timemachine \
		$(TIMECAPSULE_IMAGE)

upgrade_timecapsule: ## upgrade and launch a new timecapsule container
	$(MAKE) build_timecapsule && \
	   	(docker inspect timecapsule >/dev/null && { docker stop timecapsule && docker rm timecapsule; } || true) \
		&& $(MAKE) create_timecapsule

run_smbstatus: ## run 'smbstatus' inside the running timecapsule container
	@docker exec timecapsule /usr/local/samba/bin/smbstatus

# muximux
build_muximux: ## build the muximux container
	docker pull $(MUXIMUX_IMAGE)

create_muximux:  ## create the muximux container
	docker run -d --name muximux --restart=always \
		-e PUID=65534 -e PGID=65534 \
		-p 8000:80 \
		-v /etc/muximux:/config \
		-v /etc/localtime:/etc/localtime:ro \
		$(MUXIMUX_IMAGE)

upgrade_muximux: ## upgrade and restart the muximux container
	# we use the linuxserver/muximux image which auto-upgrades on restart
	docker restart muximux

# helpers
help: ## print list of tasks and descriptions
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

.PHONY: all

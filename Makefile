# TODO:
# - plex-pass container
# - test a reboot restarts all containers

# adding a new container:
#  1. add CONTAINER_NAME var
#  2. add container to CONTAINERS list
#  3. add to build_all and create_all tasks
#  4. implement build_CONTAINER and create_CONTAINER tasks

# config
SABNZBD_IMAGE     = joemiller/sabnzbd
SONARR_IMAGE      = joemiller/sonarr
DELUGE_IMAGE      = joemiller/deluge
PLEX_IMAGE        = joemiller/plex
PLEXPY_IMAGE      = linuxserver/plexpy
COUCHPOTATO_IMAGE = linuxserver/couchpotato

CONTAINERS = sabnzbd sonarr deluge plex plexpy couchpotato

# aggregate tasks
build_all: build_sabnzbd build_sonarr build_deluge build_plex build_plexpy build_couchpotato ## build all containers

create_all: create_sabnzbd create_sonarr create_deluge create_plex create_plexpy create_couchpotato ## create and start all containers

stop_all:  ## stop all containers
	docker stop $(CONTAINERS)

restart_all:  ## restart all containers
	docker restart $(CONTAINERS)

remove_all:  ## remove all containers
	docker rm $(CONTAINERS)

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

# helpers
help: ## print list of tasks and descriptions
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

.PHONY: all

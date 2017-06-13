# adding a new container:
#  1. add <CONTAINER>_IMAGE var
#  2. add container name to CONTAINERS list
#  4. implement build_CONTAINER and create_CONTAINER tasks

# config
SABNZBD_IMAGE          = joemiller/sabnzbd
SONARR_IMAGE           = joemiller/sonarr
DELUGE_IMAGE           = joemiller/deluge
PLEX_IMAGE             = joemiller/plex
#PLEX_IMAGE             = plexinc/pms-docker
PLEXPY_IMAGE           = linuxserver/plexpy
TIMECAPSULE_IMAGE      = joemiller/timecapsule
MUXIMUX_IMAGE          = linuxserver/muximux
GO_CARBON_IMAGE        = joemiller/go-carbon
GRAPHITE_API_IMAGE     = brutasse/graphite-api
GRAFANA_IMAGE          = grafana/grafana
COLLECTD_DOCKER_IMAGE  = bobrik/collectd-docker

CONTAINERS = sabnzbd sonarr deluge plex plexpy timecapsule muximux go-carbon graphite-api grafana collectd-docker

## network definitions
## TODO: refactor this into something a little cleaner

# A docker network will be created for containers (such as 'timecapsule') that require
# their own IP address on the local network (similar to a VM in bridge networking mode).
# NOTE: --subnet=2001::0/64 is a "dummy" network. This is required for docker 1.12.4+ which requires a
#       --subnet if --ipv6 is specified. Your network should use IPv6 SLAAC so that the container will
#       automatically acquire an ipv6 address from the real local subnet.
NETWORK_NAME=localnet-v6only
NETWORK_IFACE=br0
NETWORK_CREATE_CMD=docker network create --driver=macvlan \
				   --ipv6 --subnet=2001::0/64 \
				   -o parent=$(NETWORK_IFACE) \
				   $(NETWORK_NAME)

# a user-defined bridge network to connect metrics containers (go-carbon, graphite-api, grafana)
# together since --link is deprecated.
METRICS_NETWORK_NAME=metrics
METRICS_NETWORK_CREATE_CMD=docker network create --driver=bridge \
						   --subnet=192.168.1.0/24 --gateway=192.168.1.1 \
						   $(METRICS_NETWORK_NAME)

# helper tasks
_configure_networks:
	@docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || $(NETWORK_CREATE_CMD)
	@docker network inspect $(METRICS_NETWORK_NAME) >/dev/null 2>&1 || $(METRICS_NETWORK_CREATE_CMD)

_remove_networks:
	@docker network rm $(NETWORK_NAME)
	@docker network rm $(METRICS_NETWORK_NAME)

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
		-l collectd_docker_app=sabnzbd \
		-l collectd_docker_task=sabnzbd \
		-p 8085:8085 \
		-v /files:/files \
		-v /etc/sabnzbd:/config \
		-v /etc/localtime:/etc/localtime:ro \
		$(SABNZBD_IMAGE)

upgrade_sabnzbd: ## upgrade and launch a new sabnzbd container
	$(MAKE) build_sabnzbd && \
	   	(docker inspect sabnzbd >/dev/null && { docker stop sabnzbd && docker rm sabnzbd; } || true) \
		&& $(MAKE) create_sabnzbd

# sonarr
build_sonarr:  ## build the sonarr container
	docker build -t $(SONARR_IMAGE) --pull=true --no-cache=true sonarr

create_sonarr:  ## create and start the sonarr container
	docker run -d --name sonarr --restart=always \
		-l collectd_docker_app=sonarr \
		-l collectd_docker_task=sonarr \
		-e XDG_CONFIG_HOME=/config \
		-p 8989:8989 \
		-v /files:/files \
		-v /etc/sonarr:/config \
		-v /etc/localtime:/etc/localtime:ro \
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
		-l collectd_docker_app=deluge \
		-l collectd_docker_task=deluge \
		-p 8083:8083 \
		-p 53160:53160 \
		--net=host \
		-v /files:/files \
		-v /etc/deluge:/config \
		$(DELUGE_IMAGE)

upgrade_deluge: ## upgrade and launch a new deluge container
	$(MAKE) build_deluge && \
	   	(docker inspect deluge >/dev/null && { docker stop deluge && docker rm deluge; } || true) \
		&& $(MAKE) create_deluge

# plex
build_plex:  ## build the plex container
	#docker pull $(PLEX_IMAGE)
	./plex/plexupdate.sh -r | tail -1 | tee ./plex/download_url
	docker build -t $(PLEX_IMAGE) --pull=true --no-cache=true plex

create_plex:  ## create the plex container
	@echo "NOTE: make sure you have run 'chown -R nobody:nobody /etc/plex' before creating the plex container."
	docker run -d --name plex --restart=always \
		-l collectd_docker_app=plex \
		-l collectd_docker_task=plex \
		-p 32400:32400 \
		--net=host \
		-v /files:/files \
		-v /etc/plex:/config \
		--device /dev/dri:/dev/dri \
		$(PLEX_IMAGE)

	# for the official image:
		# -v /etc/plex:/config \
		# -v /files:/data \

upgrade_plex: ## upgrade and launch a new plex container
	$(MAKE) build_plex && \
	   	(docker inspect plex >/dev/null && { docker stop plex && docker rm plex; } || true) \
		&& $(MAKE) create_plex

# plexpy
build_plexpy: ## build the plexpy container
	docker pull $(PLEXPY_IMAGE)

create_plexpy:  ## create the plexpy container
	docker run -d --name plexpy --restart=always \
		-l collectd_docker_app=plexpy \
		-l collectd_docker_task=plexpy \
		-e PUID=65534 -e PGID=65534 \
		-p 8181:8181 \
		-v /etc/plexpy:/config \
		-v /etc/localtime:/etc/localtime:ro \
		$(PLEXPY_IMAGE)

upgrade_plexpy: ## upgrade and restart the plexpy container
	# we use the linuxserver/plexpy image which auto-upgrades on restart
	docker restart plexpy

# timecapsule (samba)
build_timecapsule:  ## build the timecapsule (samba) container
	docker build -t $(TIMECAPSULE_IMAGE) --pull=true timecapsule

create_timecapsule: _configure_networks ## create and start the timecapsule (samba) container
	docker run -d --name timecapsule --restart=always \
		-l collectd_docker_app=timecapsule \
		-l collectd_docker_task=timecapsule \
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
		-l collectd_docker_app=muximux \
		-l collectd_docker_task=muximux \
		-e PUID=65534 -e PGID=65534 \
		-p 8000:80 \
		-v /etc/muximux:/config \
		-v /etc/localtime:/etc/localtime:ro \
		$(MUXIMUX_IMAGE)

upgrade_muximux: ## upgrade and restart the muximux container
	# we use the linuxserver/muximux image which auto-upgrades on restart
	docker restart muximux

# go-carbon
build_go-carbon: ## build the go-carbon container
	docker build -t $(GO_CARBON_IMAGE) --pull=true --no-cache=true go-carbon

create_go-carbon: _configure_networks ## create and start the go-carbon container
	docker run -d --name go-carbon --restart=always \
		-l collectd_docker_app=go-carbon \
		-l collectd_docker_task=go-carbon \
		-p 2003:2003 \
		-p 2003:2003/udp \
		-p 2004:2004 \
		-p 7002:7002 \
		-p 8080:8080 \
		--network=metrics \
		-v /etc/go-carbon/data:/data \
		-v /etc/go-carbon/config:/config \
		$(GO_CARBON_IMAGE)

upgrade_go-carbon: ## upgrade and launch a new go-carbon container
	$(MAKE) build_go-carbon && \
	   	(docker inspect go-carbon >/dev/null && { docker stop go-carbon && docker rm go-carbon; } || true) \
		&& $(MAKE) create_go-carbon

# graphite-api
build_graphite-api: ## build the graphite-api container
	docker pull $(GRAPHITE_API_IMAGE)

create_graphite-api: _configure_networks ## create and start the graphite-api container
	docker run -d --name graphite-api --restart=always \
		-l collectd_docker_app=graphite-api \
		-l collectd_docker_task=graphite-api \
		--network=metrics \
		-v /etc/graphite-api/graphite-api.yaml:/etc/graphite-api.yaml \
		-v /etc/go-carbon/data:/data \
		$(GRAPHITE_API_IMAGE)

upgrade_graphite-api: ## upgrade and launch a new graphite-api container
	$(MAKE) build_graphite-api && \
	   	(docker inspect graphite-api >/dev/null && { docker stop graphite-api && docker rm graphite-api; } || true) \
		&& $(MAKE) create_graphite-api

# grafana
build_grafana: ## build the grafana container
	docker pull $(GRAFANA_IMAGE)

create_grafana: _configure_networks ## create and start the grafana container
	docker run -d --name grafana --restart=always \
		-l collectd_docker_app=grafana \
		-l collectd_docker_task=grafana \
		--network=metrics \
		-p 3000:3000 \
		-e "GF_INSTALL_PLUGINS=grafana-clock-panel" \
		-v /etc/grafana:/var/lib/grafana \
		$(GRAFANA_IMAGE)

upgrade_grafana: ## upgrade and launch a new grafana container
	$(MAKE) build_grafana && \
	   	(docker inspect grafana >/dev/null && { docker stop grafana && docker rm grafana; } || true) \
		&& $(MAKE) create_grafana

# collectd-docker
build_collectd-docker: ## build the collectd-docker container
	docker pull $(COLLECTD_DOCKER_IMAGE)

create_collectd-docker: _configure_networks ## create and start the collectd-docker container
	docker run -d --name collectd-docker --restart=always \
		-l collectd_docker_app=collectd-docker \
		-l collectd_docker_task=collectd-docker \
		--network=metrics \
		-e GRAPHITE_HOST=go-carbon \
		-e COLLECTD_HOST=$$(hostname -s) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$(COLLECTD_DOCKER_IMAGE)

upgrade_collectd-docker: ## upgrade and launch a new collectd-docker container
	$(MAKE) build_collectd-docker && \
	   	(docker inspect collectd-docker >/dev/null && { docker stop collectd-docker && docker rm collectd-docker; } || true) \
		&& $(MAKE) create_collectd-docker

# helpers
help: ## print list of tasks and descriptions
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

.PHONY: all

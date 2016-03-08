# TODO:
# x deluge container
# - figure out how the fuck to build workflows for sonarr and sab
# - plex-pass container
# x make containers run as non-root users
# - test a reboot restarts all containers


# config
SABNZBD_IMAGE = joemiller/sabnzbd
SONARR_IMAGE  = joemiller/sonarr
DELUGE_IMAGE  = joemiller/deluge

# macros
EXISTS = @docker inspect --format='{{ .State.Running }}'

# aggregate tasks
start_all: start_sabnzbd start_sonarr start_deluge ## start all containers

build_all: build_sabnzbd build_sonarr build_deluge ## build all containers

# sabnzbd
build_sabnzbd:
	docker build -t $(SABNZBD_IMAGE) sabnzbd

_rm_sabnzbd:
	$(EXISTS) sabnzbd && docker rm sabnzbd || true

_create_sabnzbd: build_sabnzbd
	$(EXISTS) sabnzbd || docker create --name sabnzbd --restart=always \
		-p 8085:8085 \
		-v /files:/files \
		-v /etc/sabnzbd:/config \
		$(SABNZBD_IMAGE)

start_sabnzbd: ## start the sabnzbd container
	docker start sabnzbd

stop_sabnzbd: ## stop the sabnzbd container
	$(EXISTS) sabnzbd && docker stop sabnzbd || true

restart_sabnzbd: ## restart the sabnzbd container

# sonarr
build_sonarr:
	docker build -t $(SONARR_IMAGE) sonarr

_rm_sonarr:
	$(EXISTS) sonarr && docker rm sonarr || true

_create_sonarr: build_sonarr
	$(EXISTS) sonarr || docker create --name sonarr --restart=always \
		-p 8989:8989 \
		-v /files:/files \
		-v /etc/sonarr:/config \
		$(SONARR_IMAGE)

start_sonarr: ## start the sonarr container
	docker start sonarr

stop_sonarr: ## stop the sonarr container
	$(EXISTS) sonarr && docker stop sonarr || true

restart_sonarr: ## restart the sonarr container

# deluge
build_deluge:
	docker build -t $(DELUGE_IMAGE) deluge

_rm_deluge:
	$(EXISTS) deluge && docker rm deluge || true

_create_deluge: build_deluge
	$(EXISTS) deluge || docker create --name deluge --restart=always \
		-p 8083:8083 \
		-p 53160:53160 \
		--net=host \
		-v /files:/files \
		-v /etc/deluge:/config \
		$(DELUGE_IMAGE)

start_deluge: ## start the deluge container
	docker start deluge

stop_deluge: ## stop the deluge container
	$(EXISTS) deluge && docker stop deluge || true

restart_deluge: ## restart the deluge container

# helpers
help: ## print list of tasks and descriptions
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

.PHONY: all

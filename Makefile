start: ## create and start all docker containers
	@docker-compose up -d

rebuild: ## rebuild and recreate container specified in CONTAINER= arg
	@if [ -z "$(CONTAINER)" ]; then \
		echo "ERROR: Must specify CONTAINER="; \
		exit 1; \
	fi
	@if [ "$(CONTAINER)" = "plex" ]; then \
		make _update-plex-version-file; \
	fi
	@docker-compose build --pull --no-cache $(CONTAINER)
	@docker-compose up -d --force-recreate $(CONTAINER)

rebuild-all:: _update-plex-version-file
rebuild-all:: build-utility-images
rebuild-all:: ## rebuild and recreate all containers
	@docker-compose up -d --build --force-recreate

build-utility-images:: build-snapraid
build-utility-images:: build-rclone
build-utility-images:: build-mergerfs-tools
build-utility-images:: build-backup-scripts

build-snapraid: ## rebuild ./snapraid image
	@docker build --no-cache --pull -t joemiller/snapraid ./snapraid

build-rclone: ## rebuild ./rclone image
	@docker build --no-cache --pull -t joemiller/rclone ./rclone

build-mergerfs-tools: ## rebuild ./mergerfs-tools image
	@docker build --no-cache --pull -t joemiller/mergerfs-tools ./mergerfs-tools

build-backup-scripts: ## rebuild ./backup-scripts image
	@docker build --no-cache --pull -t joemiller/backup-scripts ./backup-scripts

_update-plex-version-file:
	@./plex/plexupdate.sh -r | tail -1 | tee ./plex/download_url

# helpers
help: ## print list of tasks and descriptions
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

.PHONY: all

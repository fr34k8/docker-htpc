start: ## create and start all docker containers
	@docker-compose up -d

rebuild: ## rebuild and recreate container specified in CONTAINER= arg
	@if [ -z "$(CONTAINER)" ]; then \
		echo "ERROR: Must specify CONTAINER="; \
		exit 1; \
	fi
	#@docker-compose pull --parallel $(CONTAINER)
	@docker-compose build --pull --no-cache $(CONTAINER)
	@docker-compose up -d --force-recreate $(CONTAINER)

rebuild-all:: _update-plex-version-file ## rebuild and recreate all containers
	@docker-compose up -d --build --force-recreate

_update-plex-version-file:
	@./plex/plexupdate.sh -r | tail -1 | tee ./plex/download_url

rebuild-plex: CONTAINER=plex ## special task for rebuild and recreate of the Plex container
rebuild-plex: _update-plex-version-file
rebuild-plex: rebuild

# helpers
help: ## print list of tasks and descriptions
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

.PHONY: all

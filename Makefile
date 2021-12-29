pull: ## pull all pullable docker images
	@docker-compose pull --ignore-pull-failures --parallel

up: ## create and start all docker containers
	@docker-compose up -d --build

start: up ## alias for 'up'

# start: ## create and start all docker containers
# 	@docker-compose up -d --build

# rebuild: ## rebuild and recreate container specified in CONTAINER= arg
# 	@if [ -z "$(CONTAINER)" ]; then \
# 		echo "ERROR: Must specify CONTAINER="; \
# 		exit 1; \
# 	fi
# 	@docker-compose build --pull --no-cache $(CONTAINER)
# 	@docker-compose up -d --force-recreate $(CONTAINER)

# rebuild-all:: build-utility-images
# rebuild-all:: ## rebuild and recreate all containers
# 	@docker-compose up -d --build --force-recreate

# build-utility-images:: build-snapraid
# build-utility-images:: build-mergerfs-tools
# build-utility-images:: build-backup-scripts

# build-snapraid: ## rebuild ./snapraid image
# 	@docker build --no-cache --pull -t joemiller/snapraid ./snapraid

# build-mergerfs-tools: ## rebuild ./mergerfs-tools image
# 	@docker build --no-cache --pull -t joemiller/mergerfs-tools ./mergerfs-tools

# build-backup-scripts: ## rebuild ./backup-scripts image
# 	@docker build --no-cache --pull -t joemiller/backup-scripts ./backup-scripts

# helpers
help: ## print list of tasks and descriptions
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

.PHONY: all

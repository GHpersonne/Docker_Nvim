# Nom de l'image et du container
IMAGE ?= lazyvim-nvim
CONTAINER ?= $(IMAGE)

# Dossier de travail dans le conteneur
WORKDIR ?= /workspace

# Volumes pour persister config/data/cache (désactivés par défaut pour profiter du prébuild)
# Pour activer, décommentez les lignes ci-dessous.
# NVIM_CONFIG ?= $(HOME)/.config/nvim
# NVIM_DATA   ?= $(HOME)/.local/share/nvim
# NVIM_CACHE  ?= $(HOME)/.cache/nvim

# Détection OS pour le current dir (compatible Linux/macOS)
PWD_REAL := $(shell pwd)

# Options docker communes
DOCKER_RUN = docker run -it \
	-v "$(PWD_REAL):$(WORKDIR)" \
	-w "$(WORKDIR)"

# Ajouter persistance LazyVim si les dossiers existent
ifdef NVIM_CONFIG
	DOCKER_RUN += -v "$(NVIM_CONFIG):/root/.config/nvim"
endif
ifdef NVIM_DATA
	DOCKER_RUN += -v "$(NVIM_DATA):/root/.local/share/nvim"
endif
ifdef NVIM_CACHE
	DOCKER_RUN += -v "$(NVIM_CACHE):/root/.cache/nvim"
endif

.PHONY: help build run sh start stop rm rmi logs nvim rebuild prune

help:
	@echo "Cibles:"
	@echo "  make build     - Build l'image Docker ($(IMAGE))"
	@echo "  make run       - Lance nvim avec la config GHpersonne/nvim (préinstallée) dans le conteneur, monté sur le dossier courant"
	@echo "  make nvim      - Alias de run"
	@echo "  make sh        - Ouvre un shell dans le conteneur"
	@echo "  make start     - Démarre un conteneur nommé ($(CONTAINER)) puis attache nvim"
	@echo "  make stop      - Stoppe le conteneur nommé"
	@echo "  make rm        - Supprime le conteneur nommé"
	@echo "  make rmi       - Supprime l'image"
	@echo "  make logs      - Affiche les logs du conteneur"
	@echo "  make rebuild   - Rebuild no-cache"
	@echo "  make prune     - Nettoie images/volumes dangling"

build:
	docker build -t $(IMAGE) .

rebuild:
	docker build --no-cache -t $(IMAGE) .

run: build
	$(DOCKER_RUN) --rm --name $(CONTAINER) $(IMAGE) nvim

nvim: run

sh: build
	$(DOCKER_RUN) --rm --name $(CONTAINER) $(IMAGE) bash

# Mode container persistant
start: build
	docker rm -f $(CONTAINER) >/dev/null 2>&1 || true
	docker create --name $(CONTAINER) \
		-v "$(PWD_REAL):$(WORKDIR)" \
		-w "$(WORKDIR)" \
		$(IMAGE) nvim >/dev/null
	docker start -i $(CONTAINER)

stop:
	docker stop $(CONTAINER) || true

rm:
	docker rm -f $(CONTAINER) || true

rmi:
	docker rmi $(IMAGE) || true

logs:
	docker logs -f $(CONTAINER)

prune:
	docker system prune -f


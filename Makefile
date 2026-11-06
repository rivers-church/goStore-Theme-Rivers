SHELL := /bin/bash

KAMAL ?= kamal
SERVER ?= it_admin@work-docker01

GOSTORE_REPO ?= https://github.com/17xande-dev/gostore.git
# The gostore release the image is built on, read from the Dockerfile so local dev runs what deploys.
GOSTORE_REF := $(shell sed -n 's/^ARG GOSTORE_VERSION=//p' Dockerfile)
GOSTORE_DIR ?= .gostore
# gostore's own `make up` and friends, run in the checkout with this theme layered on.
export THEME_DIR := $(CURDIR)
GOSTORE_MAKE = $(MAKE) -C $(GOSTORE_DIR) COMPOSE="docker compose -f compose.yaml -f $(CURDIR)/compose.dev.yaml"

.PHONY: deploy logs-prod backup gostore dev dev-logs dev-token dev-down

## deploy: build the image (gostore at the pinned release + this theme), push it, and swap it in on work-docker01
# Kamal builds from HEAD, not the working tree, so a dirty tree is refused: the image tag
# is a commit sha and must name the theme that is inside it. The gostore release is pinned
# in the Dockerfile.
deploy:
	@git diff --quiet HEAD -- || { echo "deploy: tracked files have uncommitted changes; commit first so the tag names what runs" >&2; exit 1; }
	$(KAMAL) deploy

## logs-prod: follow the app's logs
logs-prod:
	$(KAMAL) app logs -f

## backup: pg_dump the store's database into ./backups (gitignored)
# A copy on this machine, taken over ssh from inside the postgres container.
backup:
	@mkdir -p backups; f=backups/gostore-$$(date -u +%Y%m%dT%H%M%SZ).sql.gz; \
	ssh $(SERVER) 'docker exec gostore-postgres pg_dump -U gostore gostore' | gzip > "$$f.partial" \
	  && gunzip -c "$$f.partial" | tail -n 20 | grep -q 'PostgreSQL database dump complete' \
	  && mv "$$f.partial" "$$f" && echo "$$f" || { rm -f "$$f.partial"; echo "backup failed" >&2; exit 1; }

## gostore: clone gostore into .gostore if it is not there, and check out the pinned release
gostore:
	@[ -d $(GOSTORE_DIR)/.git ] || git clone $(GOSTORE_REPO) $(GOSTORE_DIR)
	@git -C $(GOSTORE_DIR) cat-file -e $(GOSTORE_REF)^{commit} 2>/dev/null || git -C $(GOSTORE_DIR) fetch origin
	@git -C $(GOSTORE_DIR) checkout -q --detach $(GOSTORE_REF)

## dev: start the local store (gostore + Postgres + mailpit) with this theme, reloading on refresh
dev: gostore
	$(GOSTORE_MAKE) up
	@# The server migrates the database on boot; wait for that before anything uses it.
	@curl -fs --retry 30 --retry-delay 1 --retry-all-errors -o /dev/null http://localhost:8080/healthz
	@echo "next: make dev-token for the /admin/setup token, then add products in the admin"

## dev-logs: follow the local server's logs
dev-logs:
	$(GOSTORE_MAKE) logs

## dev-token: print the one-time token that claims the first admin account at /admin/setup
dev-token:
	@cd $(GOSTORE_DIR) && docker compose logs server | grep setup_token

## dev-down: stop the local stack (make dev-down ARGS=-v also deletes its data)
dev-down:
	$(GOSTORE_MAKE) down ARGS="$(ARGS)"

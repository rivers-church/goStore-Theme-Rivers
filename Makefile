SHELL := /bin/bash

# The gostore release to run. Pinned: the server runs exactly this tag, so a deploy
# never changes the version by accident. Bump it deliberately (and diff the copied
# theme files against that release, see README "What is overridden").
GOSTORE_VERSION ?= v0.2.2

KAMAL ?= kamal
SERVER ?= it_admin@work-docker01

.PHONY: theme deploy logs-prod backup

## theme: copy this theme to the server (read-only mount at /theme in the container)
# gostore reads templates and static files from disk, so new templates apply on the next
# deploy/restart of the app. --delete drops files removed from the repo.
theme:
	ssh $(SERVER) 'mkdir -p ~/gostore/theme'
	rsync -a --delete --exclude .git --exclude Makefile templates static README.md $(SERVER):gostore/theme/

## deploy: deploy the pinned gostore release behind kamal-proxy (pulls the published image; builds nothing)
deploy: theme
	$(KAMAL) deploy --skip-push --version=$(GOSTORE_VERSION)

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

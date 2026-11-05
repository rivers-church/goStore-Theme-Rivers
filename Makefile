SHELL := /bin/bash

KAMAL ?= kamal
SERVER ?= it_admin@work-docker01

.PHONY: deploy logs-prod backup

## deploy: build the image (gostore release + this theme), push it, and swap it in on work-docker01
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

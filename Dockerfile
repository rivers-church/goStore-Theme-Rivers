# The Rivers Church store: the published gostore release with this theme baked in.
# Kamal builds this and pushes it to ghcr.io/rivers-church/gostore (it also needs the
# `service` label Kamal puts on its own builds, which the upstream image lacks).
#
# Bump GOSTORE_VERSION deliberately, and diff the copied theme files against that
# release first (see README "What is overridden"). `make dev` checks out the same tag.
ARG GOSTORE_VERSION=v0.4.0
FROM ghcr.io/17xande-dev/gostore:${GOSTORE_VERSION}

COPY templates /theme/templates
COPY static /theme/static

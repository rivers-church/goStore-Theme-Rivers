# The Rivers Church store: gostore, built from its own repo at a pinned commit, with this
# theme baked in. Kamal builds this and pushes it to ghcr.io/rivers-church/gostore (it also
# needs the `service` label Kamal puts on its own builds, which the upstream image lacks).
#
# GOSTORE_REF is a full commit sha, not a branch, so a build is repeatable; `make dev` checks
# out the same one. It is a commit rather than the published image because the Rivers theme
# was updated to the newest gostore before a release (the last is v0.3.3) was cut for it.
# Bump it deliberately, and diff the copied theme files against that commit first (see
# README "What is overridden").
ARG GOSTORE_REF=8a11ad094870c8ea8f84df1c06e9e754ef481b3f

FROM golang:1.27-alpine AS build
ARG GOSTORE_REF
RUN apk add --no-cache git
WORKDIR /src
RUN git init -q . \
 && git remote add origin https://github.com/17xande-dev/gostore.git \
 && git fetch -q --depth 1 origin "$GOSTORE_REF" \
 && git checkout -q FETCH_HEAD
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/gostore .

# Writable /images and /downloads, as gostore's own Dockerfile makes them. Unused while the
# store is on R2, but the image must stay a drop-in for gostore's.
RUN mkdir -p /images /downloads && chown -R 65532:65532 /images /downloads

FROM gcr.io/distroless/static-debian13:nonroot
COPY --from=build /out/gostore /gostore
# 65532 is distroless's nonroot uid.
COPY --from=build --chown=65532:65532 /images /images
COPY --from=build --chown=65532:65532 /downloads /downloads
COPY templates /theme/templates
COPY static /theme/static
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/gostore"]

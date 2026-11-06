# The Rivers Church store: gostore, built from its own repo at a pinned commit, with this
# theme baked in. Kamal builds this and pushes it to ghcr.io/rivers-church/gostore (it also
# needs the `service` label Kamal puts on its own builds, which the upstream image lacks).
#
# GOSTORE_REF is the commit of gostore v0.4.0 (a sha rather than the tag, so a build cannot
# move); `make dev` checks out the same one. Bump it deliberately, and diff the copied theme
# files against that release first (see README "What is overridden").
ARG GOSTORE_REF=2a286a6e18baad916469ef45330ef5093dadf6d1

FROM golang:1.27.3-alpine AS build
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

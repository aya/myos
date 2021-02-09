FROM golang:1.12-alpine AS builder
LABEL maintainer 1001Pharmacies <technique+docker@1001pharmacies.com>
ARG DOCKER_BUILD_DIR

ARG GOOFYS_VERSION=v0.20.0

WORKDIR /go/src/github.com/kahing/goofys/

RUN apk --no-cache upgrade \
 && apk --no-cache add git make \
 && git clone https://github.com/kahing/goofys/ . \
 && git checkout tags/${GOOFYS_VERSION} -b ${GOOFYS_VERSION} \
 && go get . \
 && make install

FROM alpine:latest as dist
ARG DOCKER_BUILD_DIR
RUN apk add --no-cache ca-certificates
COPY --from=builder /go/bin/goofys /bin/goofys

ENTRYPOINT ["/bin/goofys"]

# goofys -f --region $REGION --stat-cache-ttl $STAT_CACHE_TTL --type-cache-ttl $TYPE_CACHE_TTL --dir-mode $DIR_MODE --file-mode $FILE_MODE -o nonempty $BUCKET $MOUNT_DIR

FROM dist as local
ARG DOCKER_BUILD_DIR

FROM local as debug
ARG DOCKER_BUILD_DIR

FROM local as tests
ARG DOCKER_BUILD_DIR

FROM tests as preprod
ARG DOCKER_BUILD_DIR

FROM preprod as prod
ARG DOCKER_BUILD_DIR

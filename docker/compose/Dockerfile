FROM alpine:latest as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR

ARG COMPOSE_REMOTE=https://github.com/docker/compose
ARG COMPOSE_VERSION=2.5.0
ARG SYSTEM=Linux
ARG MACHINE=x86_64

RUN apk update \
 && apk add --no-cache ca-certificates \
 && OS="$(echo ${SYSTEM} |awk '{print tolower($0)}')"; \
    ARCH="$(echo ${MACHINE})"; \
    wget -qO /usr/bin/docker-compose ${COMPOSE_REMOTE}/releases/download/v${COMPOSE_VERSION}/docker-compose-${OS}-${ARCH} \
 && chmod +x /usr/bin/docker-compose

ENTRYPOINT ["/usr/bin/docker-compose"]

FROM dist as master
ARG DOCKER_BUILD_DIR

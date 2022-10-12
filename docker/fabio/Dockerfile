FROM alpine:latest as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR

ARG FABIO_REMOTE=https://github.com/fabiolb/fabio
ARG FABIO_VERSION=1.6.0
ARG SYSTEM=Linux
ARG MACHINE=x86_64

RUN apk update \
 && apk add --no-cache ca-certificates \
 && OS="$(echo ${SYSTEM} |awk '{print tolower($0)}')"; \
    ARCH="$(echo ${MACHINE} |awk '/x86_64/ {print "amd64"}; /aarch64/ {print "arm64"}')"; \
    wget -qO /usr/bin/fabio ${FABIO_REMOTE}/releases/download/v${FABIO_VERSION}/fabio-${FABIO_VERSION}-${OS}_${ARCH} \
 && chmod +x /usr/bin/fabio

EXPOSE 9998 9999
ENTRYPOINT ["/usr/bin/fabio"]
CMD ["-cfg", "/etc/fabio/fabio.properties"]

HEALTHCHECK CMD status=$(echo -e 'GET /health HTTP/1.0\n' |nc -w 1 localhost 9998 | sed -n '$p') \
                 && echo "$status" && [ "$status" = "OK" ] || exit 1

FROM dist as master
ARG DOCKER_BUILD_DIR

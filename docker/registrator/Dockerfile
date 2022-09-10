FROM golang:1-alpine AS build
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR
ARG GIT_AUTHOR_NAME
ARG GIT_AUTHOR_EMAIL

ENV GIT_AUTHOR_NAME=${GIT_AUTHOR_NAME}
ENV GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL}
ENV GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME}
ENV GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL}

WORKDIR /go/src/github.com/gliderlabs/registrator/
RUN \
    apk add --no-cache git \
    && git clone https://github.com/gliderlabs/registrator/ . \
    && git reset --hard 4322fe00304d6de661865721b073dc5c7e750bd2 \
    # -useIpFromNetwork \
    && git fetch origin pull/596/head \
    && git merge --no-edit 8d904c60949e310893a25c8af3636b0151334dd4 \
    # fix SERVICE_CHECK_SCRIPT
    && git fetch origin pull/686/head \
    && git merge --no-edit 097305157a6a2c0c236fa430c17498c895536782 \
    && go mod init \
    && go mod tidy \
    && go mod vendor \
    && CGO_ENABLED=0 GOOS=linux go build \
        -a -installsuffix cgo \
        -ldflags "-X main.Version=$(cat VERSION)" \
        -o /go/bin/registrator \
        .

FROM alpine:latest as dist
ARG DOCKER_BUILD_DIR

RUN apk add --no-cache ca-certificates
COPY --from=build /go/bin/registrator /bin/registrator

ENTRYPOINT ["/bin/registrator"]
HEALTHCHECK CMD kill -SIGUSR1 1

FROM dist as master
ARG DOCKER_BUILD_DIR

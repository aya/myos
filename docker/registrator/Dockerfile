FROM golang:1-alpine AS build
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR
ARG GIT_AUTHOR_NAME
ARG GIT_AUTHOR_EMAIL

ENV GIT_AUTHOR_NAME=${GIT_AUTHOR_NAME}
ENV GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL}
ENV GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME}
ENV GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL}

WORKDIR /go/src/github.com/auto1-oss/registrator/
RUN \
    apk add --no-cache git \
    && git clone https://github.com/auto1-oss/registrator/ . \
    && git reset --hard 378a4ead31adfdae6550e112bfc186f1d1bed632 \
    # -useIpFromNetwork \
    && git fetch origin pull/18/head \
    && git merge --no-edit 5ee80693b8057d92f261b87705445a1b989239ce \
    # fix SERVICE_CHECK_SCRIPT
    && git fetch origin pull/19/head \
    && git merge --no-edit 9cfdfbee07dc6153af70f032eefc848af101fa7d \
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

FROM dist as master
ARG DOCKER_BUILD_DIR

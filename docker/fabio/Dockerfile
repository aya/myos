FROM golang:1.15-alpine AS build
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR
ARG GIT_AUTHOR_NAME
ARG GIT_AUTHOR_EMAIL

ENV GIT_AUTHOR_NAME=${GIT_AUTHOR_NAME}
ENV GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL}
ENV GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME}
ENV GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL}

WORKDIR /go/src/github.com/fabiolb/fabio
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go test -mod=vendor -trimpath -ldflags "-s -w" ./...
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -mod=vendor -trimpath -ldflags "-s -w"

FROM alpine:3.12 as master
RUN apk update && apk add --no-cache ca-certificates
COPY --from=build /src/fabio /usr/bin

ADD fabio.properties /etc/fabio/fabio.properties
EXPOSE 9998 9999
ENTRYPOINT ["/usr/bin/fabio"]
CMD ["-cfg", "/etc/fabio/fabio.properties"]

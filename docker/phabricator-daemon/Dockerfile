FROM phabricator/daemon:latest as dist
ARG DOCKER_BUILD_DIR

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        openssh-client \
 && rm -rf /var/lib/apt/lists/*

FROM dist as master
ARG DOCKER_BUILD_DIR

FROM sematext/logagent:latest as dist
ARG DOCKER_BUILD_DIR

LABEL maintainer 1001Pharmacies <technique+docker@1001pharmacies.com>

arg GIT_AUTHOR_NAME
arg GIT_AUTHOR_EMAIL

env GIT_AUTHOR_NAME=${GIT_AUTHOR_NAME:-1001Pharmacies}
env GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL:-technique+docker@1001pharmacies.com}
env GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME}
env GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL}

RUN apk add --no-cache \
        git

RUN cd / \
 && git stash \
 && git fetch -t origin pull/267/head \
 && git reset --hard refs/tags/3.0.59 \
 && git rebase d168bd0e8745a077e962248741f6be9fbeb7a8b5 \
 && git stash pop

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

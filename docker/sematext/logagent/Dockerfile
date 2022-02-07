FROM sematext/logagent:latest as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR
ARG GIT_AUTHOR_NAME
ARG GIT_AUTHOR_EMAIL

ENV GIT_AUTHOR_NAME=${GIT_AUTHOR_NAME}
ENV GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL}
ENV GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME}
ENV GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL}

RUN apk add --no-cache \
        git

RUN cd / \
 && git stash \
 && git fetch -t origin pull/267/head \
 && git reset --hard refs/tags/3.0.59 \
 && git rebase d168bd0e8745a077e962248741f6be9fbeb7a8b5 \
 && git stash pop

FROM dist as master
ARG DOCKER_BUILD_DIR

ARG IPFS_VERSION=0.13.0-rc1
FROM ipfs/go-ipfs:v${IPFS_VERSION} as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR

COPY ${DOCKER_BUILD_DIR}/*.sh /container-init.d/
RUN chmod +rx /container-init.d/*.sh

FROM dist as master
ARG DOCKER_BUILD_DIR

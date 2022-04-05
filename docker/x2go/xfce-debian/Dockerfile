FROM danger89/xfcevdi_x2go as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR

RUN apt-get update \
 && apt-get -fy upgrade \
 && apt-get -fy install \
    ecryptfs-utils \
    fail2ban \
    iptables \
    neovim \
 && apt-get clean \
 && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

COPY ${DOCKER_BUILD_DIR}/run.sh /app
COPY ${DOCKER_BUILD_DIR}/setup_ecryptfs.sh /app
COPY ${DOCKER_BUILD_DIR}/setup_locales.sh /app
COPY ${DOCKER_BUILD_DIR}/setup_sshd.sh /app
COPY ${DOCKER_BUILD_DIR}/setup_timezone.sh /app
COPY ${DOCKER_BUILD_DIR}/setup_users.sh /app

CMD []
ENTRYPOINT ["/app/run.sh"]
HEALTHCHECK CMD timeout 1 bash -c "</dev/tcp/localhost/22" 2>/dev/null 

FROM dist as master
ARG DOCKER_BUILD_DIR

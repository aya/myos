FROM alpine:latest as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR

ARG DOCKER_MACHINE=x86_64
ARG DOCKER_SYSTEM=Linux
ARG GIT_AUTHOR_EMAIL
ARG GIT_AUTHOR_NAME

ENV GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL}
ENV GIT_AUTHOR_NAME=${GIT_AUTHOR_NAME}
ENV GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL}
ENV GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME}

RUN apk upgrade --no-cache \
 && apk add --no-cache \
        bash \
        curl \
        gettext \
        git \
        gpg \
        gpg-agent \
        make \
        nano \
        netcat-openbsd \
        openssh \
        screen \
        socat \
        tmux \
        wget \
        xz

RUN git clone https://github.com/ingydotnet/git-subrepo \
 && cd git-subrepo \
 && git fetch origin +refs/heads/release/0.4.0: \
 && git checkout release/0.4.0 \
 && git fetch origin pull/314/head \
 && git rebase 9cbe7ba2f61552ce97fb312c8133813f970ab4a5 \
 && sed -i 's/install -C/install/' Makefile \
 && make install \
 && cd .. \
 && rm -rf git-subrepo

ARG COMPOSE_REMOTE=https://github.com/docker/compose
ARG COMPOSE_VERSION=2.5.0
ARG IPFS_VERSION=0.24.0

RUN OS="$(echo ${DOCKER_SYSTEM} |awk '{print tolower($0)}')" \
 && ARCH="$(echo ${DOCKER_MACHINE} |awk '{print /armv7l/ ? "armv7" : $0}')" \
 && wget -qO /usr/bin/docker-compose ${COMPOSE_REMOTE}/releases/download/v${COMPOSE_VERSION}/docker-compose-${OS}-${ARCH} \
 && chmod +x /usr/bin/docker-compose \
 && OS="$(echo ${DOCKER_SYSTEM} |awk '{print tolower($0)}')" \
 && ARCH="$(echo ${DOCKER_MACHINE})" \
 && wget -qO - https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.${OS}.${ARCH}.tar.xz \
     |tar --strip-components 1 -C /usr/local/bin -xJf - shellcheck-stable/shellcheck \
 && ARCH="$(echo ${DOCKER_MACHINE} |awk '{print /x86_64/ ? "amd64" : /arch64/ ? "arm64" : /armv(6|7)/ ? "arm" : $0}')" \
 && wget -qO - https://github.com/ipfs/kubo/releases/download/v${IPFS_VERSION}/kubo_v${IPFS_VERSION}_${OS}-${ARCH}.tar.gz \
     |tar --strip-components 1 -C /usr/local/bin -xzf - kubo/ipfs \
 && mkdir -p /usr/local/lib/shellspec \
 && wget -qO - https://github.com/shellspec/shellspec/archive/refs/heads/master.tar.gz \
     |tar --strip-components 1 -C /usr/local/lib/shellspec -xzf - \
 && ln -s /usr/local/lib/shellspec/shellspec /usr/local/bin/shellspec

ADD https://raw.github.com/kvz/cronlock/master/cronlock /usr/local/bin/cronlock
RUN chmod +rx /usr/local/bin/cronlock

# Setup environment variables; export SSH_AUTH_SOCK from socket directory
ENV SOCKET_DIR /tmp/ssh-agent
ENV SSH_AUTH_SOCK ${SOCKET_DIR}/socket
ENV SSH_AUTH_PROXY_SOCK ${SOCKET_DIR}/proxy-socket

COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["start"]

FROM dist as master
ARG DOCKER_BUILD_DIR
ARG DOCKER_GID
ARG SHELL=/bin/bash
ARG SSH_BASTION_HOSTNAME
ARG SSH_BASTION_USERNAME
ARG SSH_PRIVATE_IP_RANGE
ARG SSH_PUBLIC_HOSTS
ARG UID
ARG USER
ENV UID=${UID}
ENV GID=${UID}
ENV USER=${USER}

RUN apk add --no-cache \
        docker \
        mysql-client \
        postgresql-client \
        sudo \
        vim \
        zsh

# If we provide a numeric UID
RUN [ "$UID" -eq "$UID" ] 2>/dev/null \
# Remove user with $UID if it is not our $USER
 && if [ "$(getent passwd $UID |awk -F: '{print $1}')" != "$USER" ]; then \
      sed -i '/^'$(getent passwd $UID |awk -F: '{print $1}')':x:'$UID':/d' /etc/passwd; \
      sed -i '/^'$(getent group $GID |awk -F: '{print $1}')':x:'$GID':/d' /etc/group; \
    fi \
# Force $UID if our $USER already exists
 && sed -i 's/^'$USER':x:[0-9]\+:[0-9]\+:/'$USER':x:'$UID':'$GID':/' /etc/passwd \
 && sed -i 's/^'$USER':x:[0-9]\+:/'$USER':x:'$GID':/' /etc/group \
# Create $USER if it does not exist
 && if [ "$(getent passwd $UID)" = "" ]; then \
      echo "$USER:x:$UID:$GID::/home/$USER:$SHELL" >> /etc/passwd; \
      echo "$USER:\!:$(($(date +%s) / 60 / 60 / 24)):0:99999:7:::" >> /etc/shadow; \
      echo "$USER:x:$GID:" >> /etc/group; \
    fi \
 && mkdir -p /home/$USER \
 && chown $UID:$GID /home/$USER \
 || true

# If we provide a numeric DOCKER_GID
RUN [ "$DOCKER_GID" -eq "$DOCKER_GID" ] 2>/dev/null \
 && if [ "$(getent group docker |awk -F: '{print $3}')" != "$DOCKER_GID" ]; then \
      sed -i 's/^docker:x:[0-9]\+:/docker:x:'$DOCKER_GID':/' /etc/group; \
    fi \
|| true

## User groups
RUN adduser $USER wheel \
#  && adduser $USER docker \
 && echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

RUN echo -e "\n\
Host *\n\
  LogLevel quiet\n\
  Compression yes\n\
" >> /etc/ssh/ssh_config \
 && if [ -n "${SSH_PRIVATE_IP_RANGE}" ] && [ -n "${SSH_BASTION_HOSTNAME}" ]; then \
      echo -e "\
Host ${SSH_PRIVATE_IP_RANGE}\n\
  ProxyCommand ssh -q ssh-bastion nc -q0 %h 22\n\
  HostName %h\n\
  StrictHostKeyChecking no\n\
  UserKnownHostsFile /dev/null\n\
Host ssh-bastion\n\
  HostName ${SSH_BASTION_HOSTNAME}\
" >> /etc/ssh/ssh_config; \
      if [ -n "${SSH_BASTION_USERNAME}" ]; then \
        echo -e "\
  User ${SSH_BASTION_USERNAME}\n\
" >> /etc/ssh/ssh_config; \
      fi \
    fi

# Custom rc functions
COPY ${DOCKER_BUILD_DIR}/rc*.sh /etc/profile.d/

RUN mkdir -p $SOCKET_DIR && chown $USER $SOCKET_DIR

VOLUME ${SOCKET_DIR}

USER $USER
ENV SHELL=${SHELL}
WORKDIR /home/$USER

# git config
RUN mkdir -p ~/.ssh ~/.config/git \
 && ssh-keyscan -t rsa -H ${SSH_PUBLIC_HOSTS} >> ~/.ssh/known_hosts \
 && echo -e "\
.DS_Store\n\
.idea/\n\
.nfs*\n\
.theia/settings.json\n\
*~\n\
*.log\n\
*.swp\n\
Thumbs.db\n\
" > ~/.config/git/ignore

# dot files
COPY ${DOCKER_BUILD_DIR}/.* /home/$USER/

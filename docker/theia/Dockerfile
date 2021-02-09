FROM ubuntu:18.04 as dist
LABEL maintainer 1001Pharmacies <technique+docker@1001pharmacies.com>
ARG DOCKER_BUILD_DIR
# https://github.com/theia-ide/theia-apps/blob/master/theia-full-docker/Dockerfile

ENV DEBIAN_FRONTEND noninteractive

#Common deps
RUN apt-get update && apt-get -y dist-upgrade && apt-get -y install curl xz-utils wget gpg

#Install node and yarn
#From: https://github.com/nodejs/docker-node/blob/6b8d86d6ad59e0d1e7a94cec2e909cad137a028f/8/Dockerfile

# gpg keys listed at https://github.com/nodejs/node#release-keys
RUN set -ex \
    && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    ; do \
    gpg --batch --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
    done

ENV NODE_VERSION 8.14.1

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV YARN_VERSION 1.13.0

RUN set -ex \
    && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
    ; do \
    gpg --batch --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
    done \
    && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
    && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
    && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
    && mkdir -p /opt/yarn \
    && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn --strip-components=1 \
    && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
    && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarnpkg \
    && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

#Developer tools

## Git and sudo (sudo needed for user override)
RUN apt-get -y install git sudo

##GO
ENV GO_VERSION 1.11.4
ENV GOPATH=/usr/local/go-packages
ENV GO_ROOT=/usr/local/go
ENV PATH $PATH:/usr/local/go/bin
ENV PATH $PATH:${GOPATH}/bin

RUN curl -sS https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    go get -u -v github.com/nsf/gocode && \
    go get -u -v github.com/uudashr/gopkgs/cmd/gopkgs && \
    go get -u -v github.com/ramya-rao-a/go-outline && \
    go get -u -v github.com/acroca/go-symbols && \
    go get -u -v golang.org/x/tools/cmd/guru && \
    go get -u -v golang.org/x/tools/cmd/gorename && \
    go get -u -v github.com/fatih/gomodifytags && \
    go get -u -v github.com/haya14busa/goplay/cmd/goplay && \
    go get -u -v github.com/josharian/impl && \
    go get -u -v github.com/tylerb/gotype-live && \
    go get -u -v github.com/rogpeppe/godef && \
    go get -u -v golang.org/x/tools/cmd/godoc && \
    go get -u -v github.com/zmb3/gogetdoc && \
    go get -u -v golang.org/x/tools/cmd/goimports && \
    go get -u -v sourcegraph.com/sqs/goreturns && \
    go get -u -v github.com/golang/lint/golint && \
    go get -u -v github.com/cweill/gotests/... && \
    go get -u -v github.com/alecthomas/gometalinter && \
    go get -u -v honnef.co/go/tools/... && \
    go get -u -v github.com/sourcegraph/go-langserver && \
    go get -u -v github.com/derekparker/delve/cmd/dlv && \
    go get -u -v github.com/davidrjenni/reftools/cmd/fillstruct

#Java
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get -y install openjdk-8-jdk

#C/C++
# public LLVM PPA, development version of LLVM
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && apt-get install -y clang-tools-9 && \
    ln -s /usr/bin/clangd-9 /usr/bin/clangd

#Python 2
RUN apt-get install -y python python-pip && \
    pip install python-language-server

#PHP
RUN apt-get -y install php curl php-cli php-mbstring unzip

# https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
# https://linuxconfig.org/how-to-install-php-composer-on-debian-linux
RUN curl -s -o composer-setup.php https://getcomposer.org/installer \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php

#Ruby
RUN apt-get -y install ruby ruby-dev zlib1g-dev && \
    gem install solargraph

#Theia
##Needed for node-gyp, nsfw build
RUN apt-get install -y python build-essential

#Docker
RUN apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
 && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
 && apt-get update \
 && apt-get -y install docker-ce docker-ce-cli containerd.io

## Common tools
RUN apt-get -y install nano screen tig tmux vim-nox zsh

FROM dist as local
ARG DOCKER_BUILD_DIR
ARG DOCKER_GID
ARG SHELL=/bin/bash
ARG UID
ARG GID
ARG SSH_BASTION_HOSTNAME
ARG SSH_BASTION_USERNAME
ARG SSH_PUBLIC_HOST_KEYS
ARG SSH_PRIVATE_IP_RANGE
ARG USER
ENV UID=${UID}
ENV GID=${GID:-${UID}}
ENV USER=${USER:-root}
LABEL com.1001pharmacies.uid=${UID}
LABEL com.1001pharmacies.gid=${GID}
LABEL com.1001pharmacies.user=${USER}

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
RUN adduser $USER docker \
 && adduser $USER sudo \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

#ARG version=latest
#ADD https://raw.githubusercontent.com/theia-ide/theia-apps/master/theia-full-docker/$version.package.json /home/$USER/package.json
COPY ${DOCKER_BUILD_DIR}/package.json /home/$USER/package.json
RUN chown $USER /home/$USER/package.json

RUN echo -e "\n\
Host *\n\
  LogLevel quiet\n\
  Compression yes\n\
Host ${SSH_PRIVATE_IP_RANGE}\n\
  ProxyCommand ssh -q ssh-bastion nc -q0 %h 22\n\
  HostName %h\n\
  StrictHostKeyChecking no\n\
  UserKnownHostsFile /dev/null\n\
Host ssh-bastion\n\
  HostName ${SSH_BASTION_HOSTNAME}\n\
  User ${SSH_BASTION_USERNAME}\n\
" >> /etc/ssh/ssh_config

# Custom prompt
COPY ${DOCKER_BUILD_DIR}/rc*.sh /etc/profile.d/

USER $USER
WORKDIR /home/$USER

# using "NODE_OPTIONS=..." to avoid out-of-memory problem in CI
ARG GITHUB_TOKEN
RUN yarn --cache-folder ./ycache && rm -rf ./ycache \
 && NODE_OPTIONS="--max_old_space_size=4096" yarn theia build

# git config
RUN mkdir -p ~/.ssh ~/.config/git \
 && ssh-keyscan -t rsa -H ${SSH_PUBLIC_HOST_KEYS} >> ~/.ssh/known_hosts \
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
COPY ${DOCKER_BUILD_DIR}/.tmux /home/$USER/.tmux/

ARG GIT_AUTHOR_NAME
ARG GIT_AUTHOR_EMAIL

ENV GIT_AUTHOR_NAME=${GIT_AUTHOR_NAME:-1001Pharmacies}
ENV GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL:-technique+docker@1001pharmacies.com}
ENV GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME}
ENV GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL}

ENV SHELL=${SHELL}
ENV WORKSPACE_DIR=/Sources

ENTRYPOINT yarn theia start $WORKSPACE_DIR --hostname=0.0.0.0
EXPOSE 3000

FROM local as debug
ARG DOCKER_BUILD_DIR

FROM local as tests
ARG DOCKER_BUILD_DIR

FROM tests as preprod
ARG DOCKER_BUILD_DIR

FROM preprod as prod
ARG DOCKER_BUILD_DIR

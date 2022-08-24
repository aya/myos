FROM debian:bullseye as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR
ARG GIT_AUTHOR_NAME
ARG GIT_AUTHOR_EMAIL
ARG OPERATING_SYSTEM=Linux
ARG PROCESSOR_ARCHITECTURE=x86_64

ENV GIT_AUTHOR_NAME=${GIT_AUTHOR_NAME}
ENV GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL}
ENV GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME}
ENV GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL}

RUN apt-get update \
 && apt-get -fy install \
        bash \
        cron \
        curl \
        gettext \
        git \
        gpg \
        gpg-agent \
        make \
        nano \
        netcat-openbsd \
        openssh-client \
        python3 \
        screen \
        socat \
        sudo \
        tmux \
        vim-nox \
        wget \
        xz-utils

ADD https://git.p2p.legal/axiom-team/astrXbian/raw/branch/master/include.sh /
ADD https://git.p2p.legal/axiom-team/astrXbian/raw/branch/master/install.sh /
RUN chmod +r /include.sh \
 && chmod +rx /install.sh \
 && bash -c '. /include.sh && install_requirements'

ARG IPFS_VERSION=0.14.0

RUN { OS="$(echo ${OPERATING_SYSTEM} |awk '{print tolower($0)}')"; \
    ARCH="$(echo ${PROCESSOR_ARCHITECTURE})"; \
    wget -qO - https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.${OS}.${ARCH}.tar.xz \
     |tar --strip-components 1 -C /usr/local/bin -xJf - shellcheck-stable/shellcheck; } \
 && { OS="$(echo ${OPERATING_SYSTEM} |awk '{print tolower($0)}')"; \
    ARCH="$(echo ${PROCESSOR_ARCHITECTURE} |awk '/x86_64/ {print "amd64"}; /aarch64/ {print "arm64"}')"; \
    wget -qO - https://github.com/ipfs/kubo/releases/download/v${IPFS_VERSION}/kubo_v${IPFS_VERSION}_${OS}-${ARCH}.tar.gz \
     |tar --strip-components 1 -C /usr/local/bin -xzf - kubo/ipfs; } \
 && mkdir -p /usr/local/lib/shellspec \
 && wget -qO - https://github.com/shellspec/shellspec/archive/refs/heads/master.tar.gz \
     |tar --strip-components 1 -C /usr/local/lib/shellspec -xzf - \
 && ln -s /usr/local/lib/shellspec/shellspec /usr/local/bin/shellspec

ADD https://raw.github.com/kvz/cronlock/master/cronlock /usr/local/bin/cronlock
RUN chmod +rx /usr/local/bin/cronlock

COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]

FROM dist as master
ARG DOCKER_BUILD_DIR
ARG DOCKER_GID
ARG SHELL=/bin/bash
ARG UID
ARG USER
ENV UID=${UID}
ENV GID=${UID}
ENV USER=${USER}

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

## group sudo
RUN adduser $USER sudo \
 && echo '%sudo ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

USER $USER
ENV SHELL=${SHELL}
WORKDIR /home/$USER

# git config
RUN mkdir -p ~/.config/git \
 && echo -e "\
.DS_Store\n\
.idea/\n\
.nfs*\n\
*~\n\
*.log\n\
*.swp\n\
Thumbs.db\n\
" > ~/.config/git/ignore

RUN mkdir ~/.zen ~/astroport

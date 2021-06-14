FROM alpine:latest as dist
ARG DOCKER_BUILD_DIR

LABEL maintainer aynic.os <support+docker@asycn.io>

# Install dependencies
RUN apk add --no-cache \
        openssh \
        socat

# Setup environment variables; export SSH_AUTH_SOCK from socket directory
ENV SOCKET_DIR /tmp/ssh-agent
ENV SSH_AUTH_SOCK ${SOCKET_DIR}/socket
ENV SSH_AUTH_PROXY_SOCK ${SOCKET_DIR}/proxy-socket

# Copy entrypoint script to container
COPY ${DOCKER_BUILD_DIR}/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["ssh-agent"]

FROM dist as master
ARG DOCKER_BUILD_DIR
ARG UID
ARG GID
ARG USER
ENV UID=${UID}
ENV GID=${UID}
ENV USER=${USER}

# If we provide a specific UID
RUN let $UID >/dev/null 2>&1 \
# Remove user with $UID if it is not our $USER
 && if [ "$(getent passwd $UID |awk 'BEGIN {FS=":"} {print $1}')" != "$USER" ]; then \
      sed -i '/^'$(getent passwd $UID |awk 'BEGIN {FS=":"} {print $1}')':x:'$UID':/d' /etc/passwd; \
      sed -i '/^'$(getent group $GID |awk 'BEGIN {FS=":"} {print $1}')':x:'$GID':/d' /etc/group; \
    fi \
# Force $UID if our $USER already exists
 && sed -i 's/^'$USER':x:[0-9]\+:[0-9]\+:/'$USER':x:'$UID':'$GID':/' /etc/passwd \
 && sed -i 's/^'$USER':x:[0-9]\+:/'$USER':x:'$GID':/' /etc/group \
# Create $USER if it does not exist
 && if [ "$(getent passwd $UID)" = "" ]; then \
      echo "$USER:x:$UID:$GID::/home/$USER:/bin/false" >> /etc/passwd; \
      echo "$USER:!:$(($(date +%s) / 60 / 60 / 24)):0:99999:7:::" >> /etc/shadow; \
      echo "$USER:x:$GID:" >> /etc/group; \
    fi \
 && mkdir -p /home/$USER \
 && chown $UID:$GID /home/$USER \
 || true

RUN mkdir -p  $SOCKET_DIR && chown $USER $SOCKET_DIR

VOLUME ${SOCKET_DIR}
USER $USER

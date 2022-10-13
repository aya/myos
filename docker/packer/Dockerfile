FROM alpine:latest as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR

ARG MACHINE="x86_64"
ARG SYSTEM="Linux"

RUN apk --no-cache add \
        ansible \
        bash \
        dirmngr \
        git \
        gpg \
        gpg-agent \
        qemu \
        qemu-system-x86_64 \
        qemu-img \
        openssh-client \
        openssl \
        socat \
        wget

ARG PACKER_VERSION=1.8.3

RUN { OS="$(echo ${SYSTEM} |awk '{print tolower($0)}')"; \
    ARCH="$(echo ${MACHINE} |awk '/x86_64/ {print "amd64"}; /aarch64/ {print "arm64"}')"; \
    wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_${OS}_${ARCH}.zip \
     && wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS \
     && wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS.sig \
     && GNUPGHOME="./.gnupg" gpg --batch --recv-keys C874011F0AB405110D02105534365D9472D7468F \
     && GNUPGHOME="./.gnupg" gpg --batch --verify packer_${PACKER_VERSION}_SHA256SUMS.sig packer_${PACKER_VERSION}_SHA256SUMS \
     && grep packer_${PACKER_VERSION}_${OS}_${ARCH}.zip packer_${PACKER_VERSION}_SHA256SUMS |sha256sum -c - \
     && unzip "packer_${PACKER_VERSION}_${OS}_${ARCH}.zip" -d /usr/local/bin \
     && rm -f "packer_${PACKER_VERSION}_${OS}_${ARCH}.zip" packer_${PACKER_VERSION}_SHA256SUMS.sig packer_${PACKER_VERSION}_SHA256SUMS ./.gnupg \
    ; }

ENTRYPOINT ["/usr/local/bin/packer"]

FROM dist as master
ARG DOCKER_BUILD_DIR
ARG UID
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

USER $USER

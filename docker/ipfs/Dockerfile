ARG IPFS_VERSION=0.14.0
FROM ipfs/kubo:v${IPFS_VERSION} as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR

COPY ${DOCKER_BUILD_DIR}/*.sh /container-init.d/
RUN chmod +rx /container-init.d/*.sh

FROM dist as master
ARG DOCKER_BUILD_DIR
ARG UID
ENV UID=${UID}
ENV USER=ipfs

# If we provide a numeric UID
RUN if [ "${UID}" -eq "${UID}" ] 2>/dev/null; then \
  # Force $UID of $USER if it exists
  if [ "$(awk -F: '$1 == "'"${USER}"'" {print $3}' /etc/passwd)" != "${UID}" ]; then \
    sed -i 's/^\('"${USER}"':x\):[0-9]\+:/\1:'"${UID}"':/' /etc/passwd; \
  fi; \
  # Create $USER if $UID does not exist
  if [ "$(awk -F: '$3 == "'"${UID}"'" {print $1}' /etc/passwd)" = "" ]; then \
    echo "${USER}:x:${UID}:${GID:-${UID}}::/home/${USER}:${SHELL:-/bin/sh}" >> /etc/passwd; \
    echo "${USER}:\!:$(($(date +%s) / 60 / 60 / 24)):0:99999:7:::" >> /etc/shadow; \
    mkdir -p /home/"${USER}"; \
  fi; \
  chown "${UID}" $(awk -F: '$1 == "'"${USER}"'" {print $(NF-1)}' /etc/passwd); \
fi

# If we provide a numeric GID
RUN if [ "${GID}" -eq "${GID}" ] 2>/dev/null; then \
  # Force $GID of $GROUP if it already exists
  if [ "$(awk -F: '$1 == "'"${GROUP}"'" {print $3}' /etc/group)" != "${GID}" ]; then \
    sed -i 's/^\('"${GROUP}"':x\):[0-9]\+:/\1:'"${GID}"':/' /etc/group; \
  fi; \
  # Create $GROUP if $GID does not exist
  if [ "$(awk -F: '$3 == "'"${GID}"'" {print $1}' /etc/group)" = "" ]; then \
    echo "${GROUP}:x:${GID}:" >> /etc/group; \
  fi; \
  # Force $GID of $USER if it exists
  if [ "$(awk -F: '$1 == "'"${USER}"'" {print $4}' /etc/passwd)" != "${GID}" ]; then \
    sed -i 's/^\('"${USER}"':x:[0-9]\+\):[0-9]\+:/\1:'"${GID}"':/' /etc/passwd; \
  fi; \
  chgrp "${GID}" $(awk -F: '$1 == "'"${USER}"'" {print $(NF-1)}' /etc/passwd); \
fi

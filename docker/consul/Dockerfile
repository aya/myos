ARG CONSUL_VERSION=1.11.1
FROM consul:${CONSUL_VERSION} as dist
LABEL maintainer aynic.os <support+docker@asycn.io>
ARG DOCKER_BUILD_DIR
ARG DOCKER_GID=999

# add user consul in group docker
RUN DOCKER_GROUP=$(awk -F: '$3 == '${DOCKER_GID}' {print $1}' < /etc/group) \
 && if [ -n "${DOCKER_GROUP}" ]; then adduser consul ${DOCKER_GROUP}; \
    else addgroup -g ${DOCKER_GID} docker && adduser consul docker; \
    fi

COPY ${DOCKER_BUILD_DIR}/docker-healthcheck /usr/local/bin/
RUN chmod +rx /usr/local/bin/docker-healthcheck

HEALTHCHECK CMD ((((echo -e 'GET /v1/health/service/consul HTTP/1.0\n' \
                     |nc -w 1 localhost:8500; echo $? >&3) \
                     |sed -n '/^\[/,$p' \
                     |jq '.[].Checks[0].Output' >&4) 3>&1) \
                     | (read err; exit $err)) 4>&1

FROM dist as master
ARG DOCKER_BUILD_DIR

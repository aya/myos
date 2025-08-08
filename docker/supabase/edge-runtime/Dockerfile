ARG SUPABASE_EDGE_RUNTIME_VERSION=v1.65.3
FROM supabase/edge-runtime:${SUPABASE_EDGE_RUNTIME_VERSION}
ARG DOCKER_BUILD_DIR=.

RUN mkdir -p /home/deno/functions
COPY ${DOCKER_BUILD_DIR}/hello/ /home/deno/functions/hello/
COPY ${DOCKER_BUILD_DIR}/main/ /home/deno/functions/main/

VOLUME /home/deno/functions
VOLUME /root/.cache

ARG SUPABASE_VECTOR_VERSION=0.28.1-alpine
FROM timberio/vector:${SUPABASE_VECTOR_VERSION}
ARG DOCKER_BUILD_DIR=.

COPY ${DOCKER_BUILD_DIR}/vector.yml /etc/vector/vector.yml

VOLUME /etc/vector

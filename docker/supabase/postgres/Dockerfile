ARG SUPABASE_POSTGRES_VERSION=15.6.1.146
FROM supabase/postgres:${SUPABASE_POSTGRES_VERSION}
ARG DOCKER_BUILD_DIR=.

COPY ${DOCKER_BUILD_DIR}/realtime.sql /docker-entrypoint-initdb.d/migrations/99-realtime.sql
COPY ${DOCKER_BUILD_DIR}/webhooks.sql /docker-entrypoint-initdb.d/init-scripts/98-webhooks.sql
COPY ${DOCKER_BUILD_DIR}/roles.sql /docker-entrypoint-initdb.d/init-scripts/99-roles.sql
COPY ${DOCKER_BUILD_DIR}/jwt.sql /docker-entrypoint-initdb.d/init-scripts/99-jwt.sql
COPY ${DOCKER_BUILD_DIR}/_supabase.sql /docker-entrypoint-initdb.d/migrations/97-_supabase.sql
COPY ${DOCKER_BUILD_DIR}/logs.sql /docker-entrypoint-initdb.d/migrations/99-logs.sql
COPY ${DOCKER_BUILD_DIR}/pooler.sql /docker-entrypoint-initdb.d/migrations/99-pooler.sql

VOLUME /etc/postgresql-custom
VOLUME /var/lib/postgres

ARG SUPABASE_KONG_VERSION=3.9.0
FROM kong:${SUPABASE_KONG_VERSION}
ARG DOCKER_BUILD_DIR=.
ARG DOCKER_NETWORK=supabase_default
ARG REALTIME_TENANT=realtime-dev

RUN mkdir -p /home/kong
COPY ${DOCKER_BUILD_DIR}/kong.yml /home/kong/temp.yml
# realtime tenant is taken from hostname in url
RUN sed -i 's/realtime-dev.supabase-realtime/'"${REALTIME_TENANT}"'.'"${DOCKER_NETWORK}"'/' /home/kong/temp.yml

VOLUME /home/kong

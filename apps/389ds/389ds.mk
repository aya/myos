389DS_REPOSITORY_URL := https://github.com/thorsten-l/389ds-docker-alpine
389DS_VERSION := 2.4.4
DOCKER_BUILD_ARGS += --build-arg BUILD_VERSION=$(389DS_VERSION)

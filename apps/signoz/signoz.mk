APP_DOCKER_DIR                            ?= deploy/docker/clickhouse-setup
APP_REPOSITORY_URL                        ?= https://github.com/SigNoz/signoz
APP_VERSION                               ?= v0.34.3
ENV_VARS                                  += SIGNOZ_FRONTEND_SERVICE_3301_TAGS
SIGNOZ_FRONTEND_SERVICE_3301_TAGS         ?= $(call urlprefix)
STACK                                     += alerting/apprise

ENV_VARS                                  += SIGNOZ_FRONTEND_SERVICE_3301_TAGS
SIGNOZ_DOCKER_DIR                         ?= deploy/docker/clickhouse-setup
SIGNOZ_FRONTEND_SERVICE_3301_TAGS         ?= $(call urlprefix)
SIGNOZ_REPOSITORY_URL                     ?= https://github.com/SigNoz/signoz
SIGNOZ_VERSION                            ?= v0.34.3
STACK                                     += alerting/apprise

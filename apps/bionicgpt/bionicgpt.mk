APP_REPOSITORY_URL                        ?= https://github.com/purton-tech/bionicgpt
APP_VERSION                               ?= v1.1.14
ENV_VARS                                  += BIONICGPT_ENVOY_SERVICE_7700_TAGS
BIONICGPT_ENVOY_SERVICE_7700_TAGS         ?= $(call tagprefix)

APM_SERVER_OSS_SERVICE_8200_NAME          ?= apm-server-oss
APM_SERVER_OSS_SERVICE_8200_TAGS          ?= $(call tagprefix,apm-server-oss,8200)
ENV_VARS                                  += APM_SERVER_OSS_SERVICE_8200_TAGS KIBANA_OSS_SERVICE_5601_TAGS
KIBANA_OSS_SERVICE_5601_NAME              ?= kibana-oss
KIBANA_OSS_SERVICE_5601_TAGS              ?= $(call tagprefix,kibana-oss,5601)

elastic-oss                               ?= elastic/apm-server-oss elastic/curator elastic/elasticsearch elastic/kibana-oss

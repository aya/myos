APM_SERVER_OSS_SERVICE_URIS               ?= $(patsubst %,apm-server-oss.%,$(APP_URIS))
APM_SERVER_OSS_SERVICE_8200_TAGS          ?= $(call urlprefix,,$(APM_SERVER_OSS_SERVICE_8200_URIS))
APM_SERVER_OSS_SERVICE_8200_URIS          ?= $(APM_SERVER_OSS_SERVICE_URIS)
ENV_VARS                                  += APM_SERVER_OSS_SERVICE_8200_TAGS KIBANA_OSS_SERVICE_5601_TAGS
KIBANA_OSS_SERVICE_URIS                   ?= $(patsubst %,kibana-oss.%,$(APP_URIS))
KIBANA_OSS_SERVICE_5601_TAGS              ?= $(call urlprefix,,$(KIBANA_OSS_SERVICE_5601_URIS))
KIBANA_OSS_SERVICE_5601_URIS              ?= $(KIBANA_OSS_SERVICE_URIS)

elastic-oss                               ?= elastic/apm-server-oss elastic/curator elastic/elasticsearch elastic/kibana-oss

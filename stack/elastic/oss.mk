APM_SERVER_OSS_SERVICE_8200_TAGS          ?= $(patsubst %,urlprefix-%,$(APM_SERVER_OSS_SERVICE_8200_URIS))
APM_SERVER_OSS_SERVICE_8200_URIS          ?= $(patsubst %,apm-server-oss.%,$(APP_URIS))
ENV_VARS                                  += APM_SERVER_OSS_SERVICE_8200_TAGS KIBANA_OSS_SERVICE_5601_TAGS
KIBANA_OSS_SERVICE_5601_TAGS              ?= $(patsubst %,urlprefix-%,$(KIBANA_OSS_SERVICE_5601_URIS))
KIBANA_OSS_SERVICE_5601_URIS              ?= $(patsubst %,kibana-oss.%,$(APP_URIS))

elastic-oss                               ?= elastic/apm-server-oss elastic/curator elastic/elasticsearch elastic/kibana-oss

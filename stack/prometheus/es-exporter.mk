ENV_VARS                                  += ES_EXPORTER_SERVICE_9206_TAGS
ES_EXPORTER_SERVICE_9206_TAGS             ?= $(patsubst %,urlprefix-%,$(ES_EXPORTER_SERVICE_9206_URIS))
ES_EXPORTER_SERVICE_9206_URIS             ?= $(patsubst %,es-exporter.%,$(APP_URIS))

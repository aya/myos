ENV_VARS                                  += ES_EXPORTER_SERVICE_9206_TAGS
ES_EXPORTER_SERVICE_URIS                  ?= $(patsubst %,es-exporter.%,$(APP_URIS))
ES_EXPORTER_SERVICE_9206_TAGS             ?= $(call urlprefix,,$(ES_EXPORTER_SERVICE_9206_URIS))
ES_EXPORTER_SERVICE_9206_URIS             ?= $(ES_EXPORTER_SERVICE_URIS)

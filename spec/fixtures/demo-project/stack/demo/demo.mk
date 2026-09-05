# computed every run, exported to compose
ENV_VARS                        += DEMO_SERVICE_80_TAGS
DEMO_SERVICE_80_TAGS            ?= $(call tagprefix,demo,80)

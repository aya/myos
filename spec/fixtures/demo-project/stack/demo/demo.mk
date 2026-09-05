# computed every run, exported to compose
ENV_VARS                        += DEMO_SERVICE_80_TAGS
DEMO_SERVICE_80_TAGS            ?= $(call tagprefix,demo,80)
# a token derived from a payload variable: the payload holds commas, which
# must not split the arguments of the macro
DEMO_JWT_PAYLOAD                ?= {"role":"anon","iss":"demo"}
DEMO_JWT                        ?= $(call JWT,,$(DEMO_JWT_PAYLOAD),secret)

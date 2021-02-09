MAKE_DIR                        := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
MAKE_FILES                      := env.mk def.mk
include $(wildcard $(patsubst %,$(MAKE_DIR)/%,$(MAKE_FILES))) $(filter-out $(wildcard $(patsubst %,$(MAKE_DIR)/%,include.mk def.*.mk $(MAKE_FILES))),$(wildcard $(MAKE_DIR)/*.mk))
include $(foreach subdir,$(MAKE_SUBDIRS),$(filter-out $(wildcard $(MAKE_DIR)/$(subdir)/def.mk $(MAKE_DIR)/$(subdir)/def.*.mk),$(wildcard $(MAKE_DIR)/$(subdir)/*.mk)))
include $(wildcard *.mk docker/*.mk stack/*.mk)

# MAKE_DIR: directory path of this file
MAKE_DIR                        := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
# MAKE_FILES: list of first files to load
MAKE_FILES                      := env.mk def.mk
# include *.mk files
## $(MAKE_DIR)/$(MAKE_FILES) $(MAKE_DIR)/*.mk
include $(wildcard $(patsubst %,$(MAKE_DIR)/%,$(MAKE_FILES))) $(filter-out $(wildcard $(patsubst %,$(MAKE_DIR)/%,include.mk def.*.mk $(MAKE_FILES))),$(wildcard $(MAKE_DIR)/*.mk))
## $(MAKE_DIR)/*/*.mk
include $(foreach subdir,$(MAKE_SUBDIRS),$(filter-out $(wildcard $(MAKE_DIR)/$(subdir)/def.mk $(MAKE_DIR)/$(subdir)/def.*.mk),$(wildcard $(MAKE_DIR)/$(subdir)/*.mk)))
## *.mk */*.mk
include $(wildcard *.mk) $(filter-out $(wildcard $(MAKE_DIR)/*.mk),$(wildcard */def.mk */def.*.mk) $(filter-out $(wildcard */def.mk */def.*.mk),$(wildcard */*.mk)))

##
# INCLUDE

# variable MAKE_DIR: Directory path of this file
MAKE_DIR                        := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
# variable MAKE_FILES: List of first files to load
MAKE_FILES                      := env.mk def.mk $(wildcard def.*.mk)
## it includes $(MAKE_DIR)/$(MAKE_FILES) $(MAKE_DIR)/*.mk
include $(wildcard $(patsubst %,$(MAKE_DIR)/%,$(MAKE_FILES))) $(filter-out $(wildcard $(patsubst %,$(MAKE_DIR)/%,$(notdir $(lastword $(MAKEFILE_LIST))) $(MAKE_FILES))),$(wildcard $(MAKE_DIR)/*.mk))
## it includes $(MAKE_DIR)/*/def.mk $(MAKE_DIR)/*/def.*.mk $(MAKE_DIR)/*/*.mk
include $(foreach subdir,$(MAKE_SUBDIRS),$(wildcard $(MAKE_DIR)/$(subdir)/def.mk $(MAKE_DIR)/$(subdir)/def.*.mk) $(filter-out $(wildcard $(MAKE_DIR)/$(subdir)/def.mk $(MAKE_DIR)/$(subdir)/def.*.mk),$(wildcard $(MAKE_DIR)/$(subdir)/*.mk)))
## it includes def.mk def.*.mk *.mk */def.mk */def.*.mk */*.mk
include $(wildcard def.mk def.*.mk) $(filter-out $(wildcard def.mk def.*.mk),$(wildcard *.mk)) $(filter-out $(wildcard $(MAKE_DIR)/*.mk),$(wildcard */def.mk */def.*.mk) $(filter-out $(wildcard */def.mk */def.*.mk),$(wildcard */*.mk)))

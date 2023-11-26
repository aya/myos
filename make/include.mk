##
# INCLUDE

# variable MAKE_DIR: Path of this file
MAKE_DIR                        := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
# variable MAKE_FILE: Name of this file
MAKE_FILE                       := $(MAKE_DIR)/$(notdir $(lastword $(MAKEFILE_LIST)))
# variable MAKE_FIRST: List of first files to load
MAKE_FIRST                      := $(MAKE_DIR)/env.mk $(MAKE_DIR)/def.mk $(wildcard $(MAKE_DIR)/def.*.mk)
# variable MAKE_LATEST: List of latest files to load
MAKE_LATEST                     := $(MAKE_DIR)/end.mk

## it includes $(MAKE_FIRST)
include $(wildcard $(MAKE_FIRST))
## it includes $(MAKE_DIR)/$(MAKE_SUBDIRS)/def.mk $(MAKE_DIR)/$(MAKE_SUBDIRS)/def.*.mk
include $(foreach subdir,$(MAKE_SUBDIRS),$(wildcard $(MAKE_DIR)/$(subdir)/def.mk $(MAKE_DIR)/$(subdir)/def.*.mk))
## if not in $(MYOS) nor $(MONOREPO), it includes def.mk def.*.mk */def.mk */def.*.mk
include $(if $(filter-out . myos,$(MYOS)),$(wildcard def.mk def.*.mk */def.mk */def.*.mk))
## it includes $(MAKE_DIR)/*.mk
include $(filter-out $(wildcard $(MAKE_FILE) $(MAKE_FIRST) $(MAKE_LATEST)),$(wildcard $(MAKE_DIR)/*.mk))
## it includes $(MAKE_DIR)/$(MAKE_SUBDIRS)/*.mk
include $(foreach subdir,$(MAKE_SUBDIRS),$(filter-out $(wildcard $(MAKE_DIR)/$(subdir)/def.mk $(MAKE_DIR)/$(subdir)/def.*.mk),$(wildcard $(MAKE_DIR)/$(subdir)/*.mk)))
## if not in $(MYOS) nor $(MONOREPO), it includes *.mk */*.mk, else stack/*.mk if in $(MYOS)
include $(if $(filter-out myos,$(MYOS)),$(if $(filter-out .,$(MYOS)),$(filter-out $(wildcard def.mk def.*.mk */def.mk */def.*.mk),$(wildcard *.mk */*.mk)),$(wildcard stack/*.mk stack/*/*.mk)))
## it includes $(MAKE_LATEST)
include $(wildcard $(MAKE_LATEST))

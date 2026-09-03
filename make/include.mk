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
## it includes $(MAKE_DIR)/*.mk
include $(filter-out $(wildcard $(MAKE_FILE) $(MAKE_FIRST) $(MAKE_LATEST)),$(wildcard $(MAKE_DIR)/*.mk))
## it includes $(MAKE_DIR)/$(MAKE_SUBDIRS)/*.mk
include $(foreach subdir,$(MAKE_SUBDIRS),$(filter-out $(wildcard $(MAKE_DIR)/$(subdir)/def.mk $(MAKE_DIR)/$(subdir)/def.*.mk),$(wildcard $(MAKE_DIR)/$(subdir)/*.mk)))
## if not in $(MYOS) nor $(MONOREPO), it includes def.mk def.*.mk */def.mk */def.*.mk *.mk */*.mk
include $(if $(filter-out . myos,$(MYOS)),$(wildcard def.mk def.*.mk */def.mk */def.*.mk) $(filter-out $(wildcard def.mk def.*.mk */def.mk */def.*.mk $(STACK_DIR_NAME)/*.mk),$(wildcard *.mk */*.mk)))
## it includes $(STACK_DIR)/*.mk $(STACK_DIR)/*/*.mk
include $(foreach stack_dir,$(STACK_DIR),$(wildcard $(stack_dir)/*.mk $(stack_dir)/*/*.mk))
## it includes $(MAKE_LATEST)
include $(wildcard $(MAKE_LATEST))

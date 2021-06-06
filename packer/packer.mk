# target packer: Call packer ARGS
.PHONY: packer
packer:
	$(call packer,$(ARGS))

# target $(PACKER_ISO_FILE): Call packer-build target
$(PACKER_ISO_FILE):
	$(eval FORCE := true)
	$(call make,packer-build,,FORCE)

# target packer-build: Fire packer-build-% for PACKER_TEMPLATE
.PHONY: packer-build
packer-build: packer-build-$(PACKER_TEMPLATE) ## Build default packer template

# target packer-build-templates: Fire PACKER_TEMPLATES
.PHONY: packer-build-templates
packer-build-templates: $(PACKER_TEMPLATES) ## Build all packer templates

# target $(PACKER_TEMPLATES): Call packer-build $@
.PHONY: $(PACKER_TEMPLATES)
ifeq ($(HOST_SYSTEM),DARWIN)
$(PACKER_TEMPLATES): DOCKER     ?= false
endif
$(PACKER_TEMPLATES):
	$(call packer-build,$@)

# target packer-build-%: Call packer-build with file packer/*/%.json
.PHONY: packer-build-%
packer-build-%: docker-build-packer
	$(if $(wildcard packer/*/$*.json),\
	 $(call packer-build,$(wildcard packer/*/$*.json)))

# target packer-qemu: Fire packer-quemu-% for PACKER_ISO_NAME
.PHONY: packer-qemu
packer-qemu: packer-qemu-$(PACKER_ISO_NAME) ## Launch iso image in qemu

# target packer-qemu-%: Call packer-qemu PACKER_OUTPUT/%.iso
.PHONY: packer-qemu-%
ifeq ($(HOST_SYSTEM),DARWIN)
packer-qemu-%: DOCKER           ?= false
endif
packer-qemu-%: docker-build-packer ## Run iso image in qemu
	$(if $(wildcard $(PACKER_OUTPUT)/$*.iso),\
	 $(call packer-qemu,$(wildcard $(PACKER_OUTPUT)/$*.iso)))

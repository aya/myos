MAKECMDARGS                     += terraform

define terraform
	$(RUN) $(call run,terraform $(1),hashicorp/)
endef

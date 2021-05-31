SUBREPO_DIR                     ?= $(CURDIR)
SUBREPO_COMMIT                  ?= $(shell git rev-parse subrepo/$(SUBREPO)/$(BRANCH) 2>/dev/null)

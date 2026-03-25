#
# Zidar - Build system scripts
# Copyright 2025-2026 Milos Tosic. All rights reserved.
# License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
#

SUBDIRS := $(sort $(dir $(wildcard */makefile)))

UNAME := $(shell uname)
ifeq ($(UNAME),$(filter $(UNAME),Linux Darwin))
ifeq ($(UNAME),$(filter $(UNAME),Darwin))
OS=darwin
else
OS=linux
endif

help:
	@echo Available targets:
	@grep -E "^[a-zA-Z0-9_-]+:.*?## .*$$" $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
else
OS=windows

help:
	@echo Available targets:
	@for /F "tokens=1,2 delims=#" %%a in ('findstr /R /C:"^[a-zA-Z0-9_-]*:.*## " $(MAKEFILE_LIST)') do @echo   [36m%%a[0m %%b
endif

.PHONY: help clean projgen $(SUBDIRS)

clean:   ## Clean all intermediate files.
	$(foreach d,$(SUBDIRS),$(MAKE) -C $(d) clean &&) echo done

projgen: ## Generate project files for all configurations.
	$(foreach d,$(SUBDIRS),$(MAKE) -C $(d) projgen &&) echo done

$(SUBDIRS):
	@$(MAKE) -C $@ $(MAKECMDGOALS)

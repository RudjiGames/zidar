#
# Zidar - Build system scripts
# Copyright 2025-2026 Milos Tosic. All rights reserved.
# License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
#

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

RG_ZIDAR_DIR?=$(CURDIR)/../../..
GENIE?=$(RG_ZIDAR_DIR)/tools/bin/$(OS)/genie $(EXTRA_GENIE_ARGS) --zidar-path=$(RG_ZIDAR_DIR)
NINJA?=$(RG_ZIDAR_DIR)/tools/bin/$(OS)/ninja

.PHONY: help

clean:   ## Clean all intermediate files.
	@echo Cleaning...
	-@rm -rf .zidar

projgen: ## Generate project files for all configurations.
	@echo Generating project files...
	$(GENIE) --with-samples --with-unittests --with-tools vs2022
	$(GENIE) --with-samples --with-unittests --with-tools --gcc=linux-clang		gmake
	$(GENIE) --with-samples --with-unittests --with-tools --gcc=linux-gcc		gmake
	$(GENIE) --with-samples --with-unittests --with-tools --gcc=osx-arm64		gmake
	$(GENIE) --with-samples --with-unittests --with-tools --xcode=osx			xcode9
	$(GENIE) --with-samples --with-unittests --with-tools --xcode=ios			xcode9
	$(GENIE) --with-samples --with-unittests --with-tools --gcc=android-arm64	gmake

# Override this in your own top-level Makefile if this is in a different path in your repo.
GO_TOOLS_FILE ?= $(REPO_ROOT)/.go-tools

# Explicitly override GOBIN so it does not inherit from the environment - this allows for a truly
# self-contained build environment for the project.
override GOBIN := $(LOCAL_DIR)/bin
export GOBIN
export PATH := $(GOBIN):$(PATH)

ifndef TEAMCITY_VERSION
ifeq ($(shell command -v asdf),)
  $(error "This repo requires asdf - see https://asdf-vm.com/guide/getting-started.html#_3-install-asdf")
endif
endif

define install_tool
	$(if $(1), \
		asdf plugin list | grep -E '^$(1)$$' &>/dev/null || asdf plugin add $(1), \
		grep -Eo '^[^#]\S+' $(REPO_ROOT)/.tool-versions | xargs -I{} bash -ec 'asdf plugin list | grep -E '^{}$$' &>/dev/null || asdf plugin add {}' \
	)
	asdf install $1
endef

.PHONY: install-tools.go
install-tools.go: install-tool.golang; ## go install tools
	$(call print-target)
	cd tools && go install -v $(shell cd tools && go list -f '{{ join .Imports " " }}' -tags=tools)

.PHONY: install-tools
install-tools: ## Install all tools
install-tools: ; $(info $(M) installing all tools)
	$(call install_tool,)

.PHONY: install-tool.%
install-tool.%: ## Install specific tool
install-tool.%: ; $(info $(M) installing $*)
	$(call install_tool,$*)

.PHONY: upgrade-tools
# ASDF plugins use different env vars for GitHub authentication when querying releases. Try to
# handle this nicely by specifying some of the known env vars to prevent rate limiting.
ifdef GITHUB_USER_TOKEN
upgrade-tools: export GITHUB_API_TOKEN=$(GITHUB_USER_TOKEN)
else
ifdef GITHUB_TOKEN
upgrade-tools: export GITHUB_API_TOKEN=$(GITHUB_TOKEN)
endif
endif
upgrade-tools: export OAUTH_TOKEN=$(GITHUB_API_TOKEN)
upgrade-tools: ## Upgrades all tools to latest available versions
upgrade-tools: ; $(info $(M) upgrading all tools to latest available versions)
	grep -Eo '^[^#]\S+' $(REPO_ROOT)/.tool-versions | xargs -I{} bash -ec 'asdf plugin list | grep -E '^{}$$' &>/dev/null || asdf plugin add {}'
	grep -v '# FREEZE' $(REPO_ROOT)/.tool-versions | \
		grep -Eo '^[^#]\S+' | \
		xargs -I{} bash -ec '\
			export VERSION="$$( \
				asdf list all {} | \
				grep -vE "(^Available versions:|-src|-dev|-latest|-stm|[-\\.]rc|-alpha|-beta|[-\\.]pre|-next|(a|b|c)[0-9]+|snapshot|master)" | \
				tail -1 \
			)" && asdf install {} $${VERSION} && asdf local {} $${VERSION}'

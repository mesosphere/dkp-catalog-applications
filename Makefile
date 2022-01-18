.DEFAULT_GOAL := help

SHELL := /bin/bash -euo pipefail

INTERACTIVE := $(shell [ -t 0 ] && echo 1)

KOMMANDER_CLI_VERSION ?= $(shell (gh release list -L 1 -R mesosphere/kommander-cli | cut -d$$'\t' -f1))
KOMMANDER_CLI_BIN = bin/$(GOOS)/$(GOARCH)/kommander
GOARCH ?= $(shell go env GOARCH)
GOOS ?= $(shell go env GOOS)

include make/repo.mk
include make/release.mk
include make/tools.mk
include make/ci.mk

ifneq ($(wildcard $(REPO_ROOT)/.pre-commit-config.yaml),)
	PRE_COMMIT_CONFIG_FILE ?= $(REPO_ROOT)/.pre-commit-config.yaml
endif

.PHONY: clean
clean: ## remove files created during build
	$(call print-target)
	cd tests && rm -f coverage.*

.PHONY: kommander
kommander: $(KOMMANDER_CLI_BIN)

.PHONY: $(KOMMANDER_CLI_BIN)
$(KOMMANDER_CLI_BIN):
	mkdir -p $(dir $@) _install
	curl -fsSL https://s3.amazonaws.com/downloads.mesosphere.io/dkp/kommander_$(KOMMANDER_CLI_VERSION)_$(GOOS)_$(GOARCH).tar.gz | tar xz -C _install 'kommander'
	mv _install/kommander $@
	rm -rf _install

.PHONY: lint
lint: ## golangci-lint
lint: install-tools.go
	$(call print-target)
	cd tests && golangci-lint run -c ${REPO_ROOT}/.golangci.yml --fix

.PHONY: test
test: ## go test with race detector and code coverage
test: install-tools.go
	$(call print-target)
	cd tests && gotestsum \
			--junitfile junit-report.xml \
			--junitfile-testsuite-name=relative \
			--junitfile-testcase-classname=short \
			-- \
			-covermode=atomic \
			-coverprofile=coverage.out \
			-race \
			-short \
			-v \
			./...
	cd tests && go tool cover -html=coverage.out -o coverage.html

.PHONY: mod-tidy
mod-tidy: ## go mod tidy
	$(call print-target)
	cd tests && go mod tidy
	cd tools && go mod tidy

.PHONY: go-clean
go-clean: ## go clean build, test and modules caches
	$(call print-target)
	cd tests && go clean -r -i -cache -testcache -modcache

.PHONY: pre-commit
pre-commit: ## Runs pre-commit on all files
pre-commit: ; $(info $(M) running pre-commit)
ifeq ($(wildcard $(PRE_COMMIT_CONFIG_FILE)),)
	$(error Cannot find pre-commit config file $(PRE_COMMIT_CONFIG_FILE). Specify the config file via PRE_COMMIT_CONFIG_FILE variable)
endif
	env SKIP=$(SKIP) pre-commit run -a --show-diff-on-failure --config $(PRE_COMMIT_CONFIG_FILE)
	git fetch origin main && gitlint --ignore-stdin --commits origin/main..HEAD

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

define print-target
    @printf "Executing target: \033[36m$@\033[0m\n"
endef

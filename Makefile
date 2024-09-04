.DEFAULT_GOAL := help

SHELL := /bin/bash -euo pipefail
REPO_ROOT := $(CURDIR)
INTERACTIVE := $(shell [ -t 0 ] && echo 1)

export GOPRIVATE ?= github.com/mesosphere
export GITHUB_ORG ?= mesosphere
export GITHUB_REPOSITORY ?= dkp-catalog-applications
export GOBIN := $(REPO_ROOT)/bin/$(GOOS)/$(GOARCH)
export PATH := $(GOBIN):$(PATH)
GOARCH ?= $(shell go env GOARCH)
GOOS ?= $(shell go env GOOS)

MINDTHEGAP_VERSION ?= v0.13.1
GOJQ_VERSION ?= v0.12.4
KOMMANDER_CLI_VERSION ?= main
export GOJQ_BIN = bin/$(GOOS)/$(GOARCH)/gojq-$(GOJQ_VERSION)
export MINDTHEGAP_BIN = bin/$(GOOS)/$(GOARCH)/mindthegap
export KOMMANDER_CLI_BIN = bin/kommander-cli

ifneq (,$(filter tar (GNU tar)%, $(shell tar --version)))
WILDCARDS := --wildcards
endif

ifneq ($(wildcard $(REPO_ROOT)/.pre-commit-config.yaml),)
	PRE_COMMIT_CONFIG_FILE ?= $(REPO_ROOT)/.pre-commit-config.yaml
else
	PRE_COMMIT_CONFIG_FILE ?= $(REPO_ROOT)/repo-infra/.pre-commit-config.yaml
endif

include make/ci.mk
include make/validate.mk
include make/release.mk
include make/tools.mk
include make/repo.mk

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

.PHONY: test
test: validate-manifests

.PHONY: clean
clean:
	$(call print-target)
	@rm -rf bin _build

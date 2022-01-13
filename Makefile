.DEFAULT_GOAL := help

SHELL := /bin/bash -euo pipefail

REPO_ROOT := $(CURDIR)

INTERACTIVE := $(shell [ -t 0 ] && echo 1)

ifneq ($(wildcard $(REPO_ROOT)/.pre-commit-config.yaml),)
	PRE_COMMIT_CONFIG_FILE ?= $(REPO_ROOT)/.pre-commit-config.yaml
else
	PRE_COMMIT_CONFIG_FILE ?= $(REPO_ROOT)/repo-infra/.pre-commit-config.yaml
endif

.PHONY: clean
clean: ## remove files created during build
	$(call print-target)
	cd tests && rm -f coverage.*

.PHONY: install-tools
install-tools: ## go install tools
	$(call print-target)
	cd tools && go install -v $(shell cd tools && go list -f '{{ join .Imports " " }}' -tags=tools)

.PHONY: lint
lint: ## golangci-lint
lint: install-tools
	$(call print-target)
	cd tests && golangci-lint run -c ${REPO_ROOT}/.golangci.yml --fix

.PHONY: test
test: ## go test with race detector and code coverage
test: install-tools
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

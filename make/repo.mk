.PHONY: repo.dev.tag
repo.dev.tag: ## Returns development tag
repo.dev.tag: gh-dkp
	gh dkp generate dev-version --repository-owner $(GITHUB_ORG) --repository-name $(GITHUB_REPOSITORY)

.PHONY: repo.supported-branches
repo.supported-branches: gh-dkp
	./hack/filter-supported-branches-branches.sh
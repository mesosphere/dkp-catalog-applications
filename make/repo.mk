.PHONY: repo.dev.tag
repo.dev.tag: ## Returns development tag
repo.dev.tag: gh-dkp
	gh dkp generate dev-version --repository-owner $(GITHUB_ORG) --repository-name $(GITHUB_REPOSITORY)

.PHONY: repo.supported-branches
repo.supported-branches: gh-dkp
	gh dkp generate dev-versions --exclude ">2.14" --json | jq --raw-output --compact-output "[.releases[] | .branch_name]"

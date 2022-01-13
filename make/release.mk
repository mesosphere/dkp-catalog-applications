S3_BUCKET ?= "downloads.mesosphere.io"
S3_ACL ?= "bucket-owner-full-control"

AIRGAPPED_BUILD_DIR := _build/airgapped
AIRGAPPED_TAR_FILE := $(AIRGAPPED_BUILD_DIR)/dkp-catalog-applications-charts-bundle.tar.gz

$(AIRGAPPED_BUILD_DIR):
	@mkdir -p $(AIRGAPPED_BUILD_DIR)

.PHONY: release.create.chart-bundle
release.create.chart-bundle: ## Creates the chart bundle via the Kommander CLI
release.create.chart-bundle: $(AIRGAPPED_BUILD_DIR) kommander; $(info $(M) Creating chart bundle)
	$(KOMMANDER_CLI_BIN) helmmirror create bundle --catalog-repository $(REPO_ROOT) --output $(AIRGAPPED_TAR_FILE)

## TODO(cbuto) Upload the chart bundle to S3
.PHONY:	release.s3.chart-bundle
release.s3.chart-bundle: RELEASE_ARCHIVE_NAME = dkp-catalog-applications-charts-bundle_$(GIT_TAG).tar.gz
release.s3.chart-bundle: install-tool.awscli release.create.chart-bundle; $(info $(M) Uploading chart bundle to S3)
	aws s3 cp --acl $(S3_ACL) $(AIRGAPPED_TAR_FILE) s3://$(S3_BUCKET)/airgapped/$(GIT_TAG)/$(RELEASE_ARCHIVE_NAME)

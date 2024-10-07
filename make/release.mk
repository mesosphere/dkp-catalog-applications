BUILD_DIR := _build
DKP_OR_NKP_PREFIX ?= nkp
IMAGE_TAR_FILE := $(BUILD_DIR)/$(DKP_OR_NKP_PREFIX)-catalog-applications-image-bundle.tar
REPO_ARCHIVE_FILE := $(BUILD_DIR)/$(DKP_OR_NKP_PREFIX)-catalog-applications.tar.gz
CHART_BUNDLE := $(BUILD_DIR)/$(DKP_OR_NKP_PREFIX)-catalog-applications-chart-bundle.tar.gz
CATALOG_IMAGES_TXT := $(BUILD_DIR)/nkp_catalog_images.txt
CATALOG_IMAGES_TXT_WHITELISTED := $(BUILD_DIR)/nkp_catalog_images_whitelisted.txt
RELEASE_S3_BUCKET ?= downloads.mesosphere.io

CATALOG_APPLICATIONS_VERSION ?= ""

ATTRIBUTION_FILE_CONTENT = "For a full list of attributed 3rd party software, see https://d2iq.com/legal/3rd"

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

.PHONY: release.save-images.tar
release.save-images.tar: $(GOJQ_BIN) $(MINDTHEGAP_BIN) $(BUILD_DIR)
release.save-images.tar:
	$(call print-target)
	@$(GOJQ_BIN) -r --yaml-input '.|flatten|sort|unique|.[]' hack/images.yaml > $(CATALOG_IMAGES_TXT)
	@$(MINDTHEGAP_BIN) create image-bundle --platform linux/amd64 --images-file $(CATALOG_IMAGES_TXT) --output-file $(IMAGE_TAR_FILE)
	@ls -latrh $(IMAGE_TAR_FILE)


.PHONY: release.whitelisted-images
release.whitelisted-images: $(GOJQ_BIN) $(BUILD_DIR)
release.whitelisted-images:
	$(call print-target)
	$(GOJQ_BIN) -r --yaml-input \
		--argjson whitelist '$(shell $(GOJQ_BIN) -rc --yaml-input '.' hack/cve/whitelist.yaml)' \
		'with_entries( select( .key | IN($$whitelist[]) ) ) | flatten | sort | unique' hack/images.yaml > $(CATALOG_IMAGES_TXT_WHITELISTED)

.PHONY: cve-reporter.push-images
cve-reporter.push-images: $(GOJQ_BIN)
cve-reporter.push-images: release.whitelisted-images
cve-reporter.push-images: CVE_REPORTER_PROJECT_VERSION ?= main
cve-reporter.push-images:
	$(call print-target)
	TMP_IMAGES_JSON=$$(mktemp) && \
	$(GOJQ_BIN) --arg NKP_CATALOG_VERSION $(CVE_REPORTER_PROJECT_VERSION) \
		-r -f ./hack/cve/convert-images-json.jq $(CATALOG_IMAGES_TXT_WHITELISTED) > $$TMP_IMAGES_JSON && \
	CVE_REPORTER_PROJECT_VERSION=$(CVE_REPORTER_PROJECT_VERSION) ./hack/cve/push-images.sh $$TMP_IMAGES_JSON && \
	rm -f $$TMP_IMAGES_JSON

.PHONY: release.repo-archive
release.repo-archive: $(BUILD_DIR)
ifeq ($(CATALOG_APPLICATIONS_VERSION),"")
	$(info CATALOG_APPLICATIONS_VERSION should be set to the version which is part of the s3 file path)
else
	git archive --format "tar.gz" -o $(REPO_ARCHIVE_FILE) \
	                              $(CATALOG_APPLICATIONS_VERSION) -- \
	                              helm-repositories services
endif

.PHONY: release.chart-bundle
release.chart-bundle: kommander-cli
	$(call print-target)
	echo "Building charts bundle from nkp-catalog-applications repository: "
	# skip kafka-operator charts for unsupported versions
	$(KOMMANDER_CLI_BIN) create chart-bundle \
		--catalog-repository $(REPO_ROOT) \
		--skip-charts kafka-operator:0.20.0,kafka-operator:0.20.2,kafka-operator:0.23.0-dev.0 \
		--output $(CHART_BUNDLE)

.PHONY: release.s3
release.s3: CHART_BUNDLE_URL = https://downloads.d2iq.com/dkp/$(CATALOG_APPLICATIONS_VERSION)/$(DKP_OR_NKP_PREFIX)-catalog-applications-charts-bundle-$(CATALOG_APPLICATIONS_VERSION).tar.gz
release.s3: REPO_ARCHIVE_URL = https://downloads.d2iq.com/dkp/$(CATALOG_APPLICATIONS_VERSION)/$(DKP_OR_NKP_PREFIX)-catalog-applications-$(CATALOG_APPLICATIONS_VERSION).tar.gz
release.s3: IMAGE_BUNDLE_URL = https://downloads.d2iq.com/dkp/$(CATALOG_APPLICATIONS_VERSION)/$(DKP_OR_NKP_PREFIX)-catalog-applications-image-bundle-$(CATALOG_APPLICATIONS_VERSION).tar
release.s3: release.add-attribution
	$(call print-target)
ifeq ($(CATALOG_APPLICATIONS_VERSION),"")
	$(info CATALOG_APPLICATIONS_VERSION should be set to the version which is part of the s3 file path)
else
	mkdir -p $(BUILD_DIR)/tmp
	mv $(CHART_BUNDLE) $(BUILD_DIR)/tmp/$(DKP_OR_NKP_PREFIX)-catalog-applications-charts-bundle-$(CATALOG_APPLICATIONS_VERSION).tar.gz
	tar cvzf $(CHART_BUNDLE) NOTICES.txt -C $(BUILD_DIR)/tmp $(DKP_OR_NKP_PREFIX)-catalog-applications-charts-bundle-$(CATALOG_APPLICATIONS_VERSION).tar.gz
	aws s3 cp --no-progress --acl bucket-owner-full-control $(CHART_BUNDLE) s3://$(RELEASE_S3_BUCKET)/dkp/$(CATALOG_APPLICATIONS_VERSION)/$(DKP_OR_NKP_PREFIX)-catalog-applications-charts-bundle-$(CATALOG_APPLICATIONS_VERSION).tar.gz
	echo "Published Chart Bundle to $(CHART_BUNDLE_URL)"
	aws s3 cp --no-progress --acl bucket-owner-full-control $(REPO_ARCHIVE_FILE) s3://$(RELEASE_S3_BUCKET)/dkp/$(CATALOG_APPLICATIONS_VERSION)/$(DKP_OR_NKP_PREFIX)-catalog-applications-$(CATALOG_APPLICATIONS_VERSION).tar.gz
	echo "Published Repo Archive File to $(REPO_ARCHIVE_URL)"
	mv $(IMAGE_TAR_FILE) $(BUILD_DIR)/tmp/$(DKP_OR_NKP_PREFIX)-catalog-applications-image-bundle-$(CATALOG_APPLICATIONS_VERSION).tar
	tar cvf $(IMAGE_TAR_FILE) NOTICES.txt -C $(BUILD_DIR)/tmp $(DKP_OR_NKP_PREFIX)-catalog-applications-image-bundle-$(CATALOG_APPLICATIONS_VERSION).tar
	aws s3 cp --no-progress --acl bucket-owner-full-control $(IMAGE_TAR_FILE)  s3://$(RELEASE_S3_BUCKET)/dkp/$(CATALOG_APPLICATIONS_VERSION)/$(DKP_OR_NKP_PREFIX)-catalog-applications-image-bundle-$(CATALOG_APPLICATIONS_VERSION).tar
	echo "Published Image Bundle to $(IMAGE_BUNDLE_URL)"
ifeq (,$(findstring dev,$(CATALOG_APPLICATIONS_VERSION)))
	# Make sure to set SLACK_WEBHOOK environment variable to webhook url for the below mentioned channel
	curl -X POST -H 'Content-type: application/json' \
	--data '{"channel":"#eng-shipit","blocks":[{"type":"header","text":{"type":"plain_text","text":":announce: NKP Catalog Applications for $(CATALOG_APPLICATIONS_VERSION) are out!","emoji":true}},{"type":"section","text":{"type":"mrkdwn","text":"*Bundles:*\n:airgap: Airgapped Image Bundle: $(IMAGE_BUNDLE_URL)\n:package: Chart Bundle: $(CHART_BUNDLE_URL)\n:github: Git Repo Tarball: $(REPO_ARCHIVE_URL)"}}]}' \
	$(SLACK_WEBHOOK)
endif
endif

.PHONY: release.add-attribution
release.add-attribution:
	@echo $(ATTRIBUTION_FILE_CONTENT) > NOTICES.txt

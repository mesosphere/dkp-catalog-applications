BUILD_DIR := _build
IMAGE_TAR_FILE := $(BUILD_DIR)/dkp-catalog-applications-image-bundle.tar.gz
REPO_ARCHIVE_FILE := $(BUILD_DIR)/dkp-catalog-applications.tar.gz
CATALOG_IMAGES_TXT := $(BUILD_DIR)/dkp_catalog_images.txt
RELEASE_S3_BUCKET ?= downloads.mesosphere.io

CATALOG_APPLICATIONS_VERSION ?= ""

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

.PHONY: release.save-images.tar
release.save-images.tar: $(GOJQ_BIN) $(MINDTHEGAP_BIN) $(BUILD_DIR)
release.save-images.tar:
	$(call print-target)
	@$(GOJQ_BIN) -r --yaml-input '.|flatten|sort|.[]' hack/images.yaml > $(CATALOG_IMAGES_TXT)
	@$(MINDTHEGAP_BIN) create image-bundle --platform linux/amd64 --images-file $(CATALOG_IMAGES_TXT) --output-file $(IMAGE_TAR_FILE)
	@ls -latrh $(IMAGE_TAR_FILE)

.PHONY: release.repo-archive
release.repo-archive: $(BUILD_DIR)
ifeq ($(CATALOG_APPLICATIONS_VERSION),"")
	$(info CATALOG_APPLICATIONS_VERSION should be set to the version which is part of the s3 file path)
else
	git archive --format "tar.gz" -o $(REPO_ARCHIVE_FILE) \
	                              $(CATALOG_APPLICATIONS_VERSION) -- \
	                              helm-repositories services
endif

.PHONY: release.s3
release.s3:
	$(call print-target)
ifeq ($(CATALOG_APPLICATIONS_VERSION),"")
	$(info CATALOG_APPLICATIONS_VERSION should be set to the version which is part of the s3 file path)
else
	aws s3 cp --no-progress --acl bucket-owner-full-control $(REPO_ARCHIVE_FILE) s3://$(RELEASE_S3_BUCKET)/dkp/$(CATALOG_APPLICATIONS_VERSION)/dkp-catalog-applications-$(CATALOG_APPLICATIONS_VERSION).tar.gz
	aws s3 cp --no-progress --acl bucket-owner-full-control $(IMAGE_TAR_FILE) s3://$(RELEASE_S3_BUCKET)/dkp/$(CATALOG_APPLICATIONS_VERSION)/dkp-catalog-applications-image-bundle-$(CATALOG_APPLICATIONS_VERSION).tar.gz
endif

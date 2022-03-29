IMAGE_BUILD_DIR := _build
IMAGE_TAR_FILE := $(IMAGE_BUILD_DIR)/catalog-applications-image-bundle.tar.gz
CATALOG_IMAGES_TXT := $(IMAGE_BUILD_DIR)/catalog_images.txt
RELEASE_S3_BUCKET ?= downloads.mesosphere.io

CATALOG_APPLICATIONS_VERSION ?= ""

$(IMAGE_BUILD_DIR):
	@mkdir -p $(IMAGE_BUILD_DIR)

.PHONY: release.save-images.tar
release.save-images.tar: $(GOJQ_BIN) $(MINDTHEGAP_BIN) $(IMAGE_BUILD_DIR)
release.save-images.tar:
	$(call print-target)
	@$(GOJQ_BIN) -r --yaml-input '.|flatten|sort|.[]' hack/images.yaml > $(CATALOG_IMAGES_TXT)
	@$(MINDTHEGAP_BIN) create image-bundle --platform linux/amd64 --images-file $(CATALOG_IMAGES_TXT) --output-file $(IMAGE_TAR_FILE)
	@ls -latrh $(IMAGE_TAR_FILE)

.PHONY: release.s3
release.s3:
	$(call print-target)
ifeq ($(CATALOG_APPLICATIONS_VERSION),"")
	$(info CATALOG_APPLICATIONS_VERSION should be set to the version which is part of the s3 file path)
else
	aws s3 cp --no-progress --acl bucket-owner-full-control $(IMAGE_TAR_FILE) s3://$(RELEASE_S3_BUCKET)/dkp/$(CATALOG_APPLICATIONS_VERSION)/catalog_applications_image_bundle_$(CATALOG_APPLICATIONS_VERSION)_linux_amd64.tar.gz
endif

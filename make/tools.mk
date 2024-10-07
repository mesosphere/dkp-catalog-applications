.PHONY: mindthegap
mindthegap: $(MINDTHEGAP_BIN)
	$(call print-target)

$(MINDTHEGAP_BIN):
	$(call print-target)
	mkdir -p $(dir $@) _install
	curl -fsSL https://github.com/mesosphere/mindthegap/releases/download/$(MINDTHEGAP_VERSION)/mindthegap_$(MINDTHEGAP_VERSION)_$(GOOS)_$(GOARCH).tar.gz | tar xz -C _install 'mindthegap'
	mv _install/mindthegap $@
	rm -rf _install

.PHONY: gojq
gojq: $(GOJQ_BIN)
	$(call print-target)

ifeq ($(GOOS),darwin)
  GOJQ_EXT := zip
else
  GOJQ_EXT := tar.gz
endif
$(GOJQ_BIN):
	$(call print-target)
	mkdir -p $(dir $@) _install
	curl -fsSL https://github.com/itchyny/gojq/releases/download/$(GOJQ_VERSION)/gojq_$(GOJQ_VERSION)_$(GOOS)_$(GOARCH).$(GOJQ_EXT) | tar xz -C _install $(WILDCARDS) --strip-components 1 '*/gojq'
	mv _install/gojq $@
	chmod 755 $@
	rm -rf _install

.PHONY: kommander-cli
kommander-cli:
	$(call print-target)
	CGO_ENABLED=0 go install github.com/mesosphere/kommander-cli/v2@$(KOMMANDER_CLI_VERSION)

.PHONY: gh-dkp
gh-dkp: ; $(info $(M) installing $*)
	gh extensions install mesosphere/gh-dkp || gh dkp -h

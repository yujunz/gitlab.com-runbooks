JSONNET_FMT_FLAGS := --string-style l -n 0 # Note: Currently, as of v0.13 jsonnetfmt will collapse multiline strings and incorrectly indent lines, so disabling these options for now
JSONNET_FILES = $(shell find . -name "*.jsonnet" -type f -not -path "./dashboards/vendor/*")

SHELL_FMT_FLAGS := -i 2 -ci
SHELL_FILES = $(shell find . -name "*.sh" -type f -not -path "./dashboards/vendor/*")

JSONET_COMMAND = $(shell which jsonnetfmt || (which jsonnet && echo " fmt"))

SHELLCHECK_FLAGS := -e SC1090,SC1091

.PHONY: all
all: verify

.PHONY: verify
verify: verify-shellcheck verify-fmt

.PHONY: verify-fmt
verify-fmt:
	$(JSONET_COMMAND) $(JSONNET_FMT_FLAGS) --test $(JSONNET_FILES)
	shfmt $(SHELL_FMT_FLAGS) -l -d $(SHELL_FILES)

.PHONY: verify-shellcheck
verify-shellcheck:
	shellcheck $(SHELLCHECK_FLAGS) $(SHELL_FILES)

.PHONY: fmt
fmt: jsonnet-fmt shell-fmt

.PHONY: jsonnet-fmt
jsonnet-fmt:
	$(JSONET_COMMAND) $(JSONNET_FMT_FLAGS) -i $(JSONNET_FILES)

.PHONY: shell-fmt
shell-fmt:
	shfmt $(SHELL_FMT_FLAGS) -w $(SHELL_FILES)

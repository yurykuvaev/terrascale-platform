.PHONY: help fmt fmt-check validate

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

TF_DIRS := $(shell find terraform -type f -name '*.tf' -exec dirname {} \; 2>/dev/null | sort -u)

help:  ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

fmt:  ## Run terraform fmt recursively
	terraform fmt -recursive terraform/

fmt-check:  ## Verify terraform formatting
	terraform fmt -check -recursive terraform/

validate:  ## terraform init -backend=false && validate per module
	@for d in $(TF_DIRS); do \
		echo "==> validating $$d"; \
		(cd "$$d" && terraform init -backend=false -input=false -no-color >/dev/null && terraform validate -no-color) || exit 1; \
	done

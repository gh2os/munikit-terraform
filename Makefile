TF_ROOTS := \
	environments/dev \
	environments/staging \
	environments/prod \
	examples/single-instance \
	examples/multi-instance

TF_MODULE_ROOTS := \
	modules/networking \
	modules/iam \
	modules/storage \
	modules/database \
	modules/munikit-app

TF_ALL_ROOTS := \
	$(TF_MODULE_ROOTS) \
	$(TF_ROOTS)

TF_TEST_ARGS ?=

.DEFAULT_GOAL := help

.PHONY: help list-roots fmt fmt-check init validate test terraform-test tflint check ci update-providers
help:
	@printf 'Available targets:\n'
	@printf '  make list-roots       Print Terraform module and runnable roots\n'
	@printf '  make fmt              Format Terraform files recursively\n'
	@printf '  make fmt-check        Check Terraform formatting recursively\n'
	@printf '  make init             Init all Terraform roots with backend disabled\n'
	@printf '  make validate         Init and validate all Terraform roots\n'
	@printf '  make test             Init and run Terraform tests where present\n'
	@printf '  make tflint           Run tflint where available\n'
	@printf '  make check            Run the full local Terraform check suite\n'
	@printf '  make ci               Alias for check\n'
	@printf '  make update-providers Update provider locks for runnable roots\n'

list-roots:
	@printf 'Module roots:\n'
	@for dir in $(TF_MODULE_ROOTS); do printf '  %s\n' "$$dir"; done
	@printf '\nRunnable roots:\n'
	@for dir in $(TF_ROOTS); do printf '  %s\n' "$$dir"; done

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -check -recursive

init:
	@set -e; \
	for dir in $(TF_ALL_ROOTS); do \
		printf '\n==> Initializing Terraform in %s\n' "$$dir"; \
		terraform -chdir="$$dir" init -backend=false -input=false; \
	done

validate:
	scripts/terraform-test.sh --all --skip-fmt --skip-test --skip-tflint

test: terraform-test

terraform-test:
	scripts/terraform-test.sh --all --skip-fmt --skip-validate --skip-tflint -- $(TF_TEST_ARGS)

tflint:
	scripts/terraform-test.sh --all --skip-fmt --skip-init --skip-validate --skip-test

check:
	scripts/terraform-test.sh --all -- $(TF_TEST_ARGS)

ci: check

update-providers:
	@set -e; \
	for dir in $(TF_ROOTS); do \
		printf '\n==> Updating Terraform providers in %s\n' "$$dir"; \
		terraform -chdir="$$dir" init -backend=false -input=false -upgrade; \
	done

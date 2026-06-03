TF_ROOTS := \
	environments/dev \
	environments/staging \
	environments/prod \
	examples/single-instance \
	examples/multi-instance

TF_TEST_ROOTS := \
	modules/networking \
	modules/iam \
	modules/storage \
	modules/database \
	modules/munikit-app \
	$(TF_ROOTS)

.PHONY: update-providers test terraform-test
update-providers:
	@set -e; \
	for dir in $(TF_ROOTS); do \
		printf '\n==> Updating Terraform providers in %s\n' "$$dir"; \
		terraform -chdir="$$dir" init -backend=false -input=false -upgrade; \
	done

test: terraform-test

terraform-test:
	@set -e; \
	for dir in $(TF_TEST_ROOTS); do \
		printf '\n==> Running Terraform tests in %s\n' "$$dir"; \
		terraform -chdir="$$dir" test; \
	done

TF_ROOTS := \
	environments/dev \
	environments/staging \
	environments/prod \
	examples/single-instance \
	examples/multi-instance

.PHONY: update-providers
update-providers:
	@set -e; \
	for dir in $(TF_ROOTS); do \
		printf '\n==> Updating Terraform providers in %s\n' "$$dir"; \
		terraform -chdir="$$dir" init -backend=false -input=false -upgrade; \
	done

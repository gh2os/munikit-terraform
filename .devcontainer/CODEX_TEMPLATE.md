# DevContainer Template

This project DevContainer was generated from the reusable template repo:

```text
/Users/g/work/personal/devcontainer
```

Template metadata is recorded in:

```text
.devcontainer/template.lock.json
```

The separate `.devcontainer/devcontainer-lock.json` records resolved
DevContainer feature digests.

Startup helpers, global Codex workflow defaults, Git guardrails, and the
firewall allowlist are copied into the image during DevContainer build. Rebuild
the DevContainer after editing helper scripts,
`.devcontainer/codex-global-agents.md`, or
`.devcontainer/codex-allowed-domains.txt`.

On first container start, `/home/vscode/.codex/AGENTS.md` is seeded from
`.devcontainer/codex-global-agents.md` only if the persisted Codex home does not
already contain non-empty global instructions.

Run Terraform project checks with:

```bash
scripts/terraform-test.sh
```

Run the full Codex/Terraform local workflow with:

```bash
scripts/codex-workflow.sh
```

Prepare remote-first pull request handoff guidance with:

```bash
scripts/codex-pr-prep.sh
```

Use `scripts/terraform-test.sh --all` for repos with multiple Terraform root
modules, or pass explicit roots with `--dir`.

Project-level Codex instructions are merged into a managed block in the root
agents file. Keep project-specific Terraform root lists and safety notes outside
that managed block.

Terraform test files can create real infrastructure depending on their run
blocks. Review project tests and credentials before running them.

Use the template repo's `tools/apply-template.sh` to refresh these files. Runtime
container behavior does not depend on the template repo being present.

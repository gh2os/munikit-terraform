# Codex DevContainer Defaults

These instructions apply to Codex sessions running inside this DevContainer.

- Start by checking `git status --short` and the current branch.
- Preserve unrelated user changes, and ask before destructive git operations,
  deploys, pushes, branch deletion, or history rewrites.
- For ambiguous or risky work, plan before editing; keep implementation changes
  small and aligned with local project patterns.
- Run the narrowest useful validation first, then broader gates when runtime,
  sandbox, Docker, dependency, or release behavior changes.
- Work on feature branches; do not commit, merge, or push directly to `main` or
  `master`.
- Final pull request creation, approval, and merge should happen in the remote
  GitHub or Bitbucket repository, not by locally merging protected branches.
- After a PR is submitted, run local read-only Codex PR review with subagents by default.
- Do not enable Codex cloud review, GitHub Actions, or automatic PR reviews
  unless explicitly requested.
- For PR reviews, spawn parallel read-only subagents for security/runtime,
  tests/docs/release, and maintainability/merge-readiness when the subagent tool
  is available. If unavailable, state the fallback clearly.
- Treat P0/P1/P2 review findings as blockers.
- Write commit messages in lowercase unless preserving an acronym or matching
  an established syntax style.
- Summarize changed files, validation results, skips, and assumptions before
  handing off.
